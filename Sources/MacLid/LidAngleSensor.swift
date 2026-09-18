import Foundation
import IOKit
import IOKit.hid

/// Reads the MacBook lid angle from the HID sensor (usage page 0x20, usage 0x8A).
/// Feature report 1 answers with [reportID, angleLow, angleHigh], angle in degrees.
/// Returns nil on Macs without the sensor (desktops, older MacBooks).
///
/// Polling rate adapts: a still lid is checked a few times a second, and the
/// fast rate lasts only while it is actually moving. Waking the CPU 60 times a
/// second to be told the lid hasn't moved is pure battery waste.
final class LidAngleSensor {

    private enum Rate {
        static let idle = 1.0 / 8
        static let idleLeeway = DispatchTimeInterval.milliseconds(80)
        static let tracking = 1.0 / 60
        static let trackingLeeway = DispatchTimeInterval.milliseconds(2)
        /// How long the fast rate lingers after the lid stops, so pauses
        /// mid-movement don't drop it back to a coarse sampling.
        static let trackingLinger = 2.0
    }

    private let manager: IOHIDManager
    private let device: IOHIDDevice
    private let queue = DispatchQueue(label: "com.francesco.maclid.lid-angle")
    private var timer: DispatchSourceTimer?
    private var onChange: ((Double) -> Void)?
    private var lastAngle: Double?
    private var lastChange = CFAbsoluteTimeGetCurrent()
    private var isTracking = false

    init?() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDPrimaryUsagePageKey: 0x20,
            kIOHIDPrimaryUsageKey: 0x8A
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess,
              let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
              let device = devices.first else {
            return nil
        }

        self.manager = manager
        self.device = device

        guard readAngle() != nil else { return nil }
    }

    func readAngle() -> Double? {
        var buffer = [UInt8](repeating: 0, count: 8)
        var length = CFIndex(buffer.count)
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 1, &buffer, &length)
        guard result == kIOReturnSuccess, length >= 3 else { return nil }

        let angle = Double(Int(buffer[1]) | (Int(buffer[2]) << 8))
        guard (0...180).contains(angle) else { return nil }
        return angle
    }

    func startMonitoring(onChange: @escaping (Double) -> Void) {
        stop()
        self.onChange = onChange

        lastChange = 0
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.setEventHandler { [weak self] in self?.tick() }
        self.timer = timer
        applyRate(tracking: false, force: true)
        timer.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        lastAngle = nil
        isTracking = false
    }

    var isRunning: Bool { timer != nil }

    private func tick() {
        guard let angle = readAngle() else { return }

        let now = CFAbsoluteTimeGetCurrent()
        let changed = angle != lastAngle
        if changed {
            lastChange = now
        }
        applyRate(tracking: now - lastChange < Rate.trackingLinger)

        guard changed else { return }
        lastAngle = angle

        let callback = onChange
        DispatchQueue.main.async { callback?(angle) }
    }

    private func applyRate(tracking: Bool, force: Bool = false) {
        guard force || tracking != isTracking else { return }
        isTracking = tracking

        timer?.schedule(
            deadline: .now(),
            repeating: tracking ? Rate.tracking : Rate.idle,
            leeway: tracking ? Rate.trackingLeeway : Rate.idleLeeway
        )
    }
}
