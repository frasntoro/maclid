import Foundation
import IOKit
import IOKit.hid

/// Reads the MacBook lid angle from the HID sensor (usage page 0x20, usage 0x8A).
/// Feature report 1 answers with [reportID, angleLow, angleHigh], angle in degrees.
/// Returns nil on Macs without the sensor (desktops, older MacBooks).
final class LidAngleSensor {

    private let manager: IOHIDManager
    private let device: IOHIDDevice
    private let queue = DispatchQueue(label: "com.francesco.maclid.lid-angle")
    private var timer: DispatchSourceTimer?
    private var lastAngle: Double?

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

    func startMonitoring(interval: TimeInterval = 1.0 / 60, onChange: @escaping (Double) -> Void) {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            guard let self, let angle = self.readAngle(), angle != self.lastAngle else { return }
            self.lastAngle = angle
            DispatchQueue.main.async { onChange(angle) }
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
}
