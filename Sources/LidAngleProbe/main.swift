import Foundation
import IOKit
import IOKit.hid

// Diagnostic tool: looks for a HID device exposing the MacBook lid angle and
// prints its raw feature report while the lid moves. Read-only.

setvbuf(stdout, nil, _IONBF, 0)

func property<T>(_ device: IOHIDDevice, _ key: String, as type: T.Type) -> T? {
    IOHIDDeviceGetProperty(device, key as CFString) as? T
}

func describe(_ device: IOHIDDevice) -> String {
    let name = property(device, kIOHIDProductKey, as: String.self) ?? "(unnamed)"
    let usagePage = property(device, kIOHIDPrimaryUsagePageKey, as: Int.self) ?? -1
    let usage = property(device, kIOHIDPrimaryUsageKey, as: Int.self) ?? -1
    return String(format: "%@ — usagePage 0x%02X, usage 0x%02X", name, usagePage, usage)
}

func readFeatureReport(_ device: IOHIDDevice, reportID: Int, length: Int = 16) -> [UInt8]? {
    var buffer = [UInt8](repeating: 0, count: length)
    var reportLength = CFIndex(length)
    let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, CFIndex(reportID), &buffer, &reportLength)
    guard result == kIOReturnSuccess, reportLength > 0 else { return nil }
    return Array(buffer.prefix(Int(reportLength)))
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerSetDeviceMatching(manager, nil)

let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
if openStatus != kIOReturnSuccess {
    print(String(format: "Warning: IOHIDManagerOpen returned 0x%08X", openStatus))
}

guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, !deviceSet.isEmpty else {
    print("No HID devices found.")
    exit(1)
}

let devices = Array(deviceSet)
print("HID devices found: \(devices.count)")

// The lid angle sensor sits on the HID sensor usage page (0x20).
let candidates = devices.filter { device in
    let usagePage = property(device, kIOHIDPrimaryUsagePageKey, as: Int.self) ?? 0
    let name = (property(device, kIOHIDProductKey, as: String.self) ?? "").lowercased()
    return usagePage == 0x20 || name.contains("lid") || name.contains("sensor") || name.contains("management")
}

print("\nSensor candidates:")
if candidates.isEmpty {
    print("  none. Full list:")
    for device in devices {
        print("  • " + describe(device))
    }
    exit(1)
}
for device in candidates {
    print("  • " + describe(device))
}

var working: [(device: IOHIDDevice, reportID: Int)] = []
for device in candidates {
    for reportID in 0...3 where readFeatureReport(device, reportID: reportID) != nil {
        working.append((device, reportID))
    }
}

guard !working.isEmpty else {
    print("\nNo readable feature report on these devices.")
    exit(1)
}

print("\nReadable reports: \(working.count). Move the lid — Ctrl+C to quit.\n")

while true {
    for entry in working {
        guard let bytes = readFeatureReport(entry.device, reportID: entry.reportID) else { continue }
        let hex = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
        let name = property(entry.device, kIOHIDProductKey, as: String.self) ?? "?"
        var decoded = ""
        if bytes.count >= 3 {
            let le16at1 = Int(bytes[1]) | (Int(bytes[2]) << 8)
            decoded = "  LE16@1=\(le16at1)"
        }
        print("[\(name) id\(entry.reportID)] \(hex)\(decoded)")
    }
    Thread.sleep(forTimeInterval: 0.25)
}
