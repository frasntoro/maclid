import AppKit

/// Raw values are what's stored in the user defaults. 2 is left unused: it
/// was the system accent colour, removed in 1.1.0 and migrated to `.color`.
enum TintSource: Int, CaseIterable {
    /// The plain glass blur, no colour on it.
    case glass = 0
    case wallpaper = 1
    case color = 3
    case gradient = 4

    static let retiredAccent = 2

    var label: String {
        switch self {
        case .glass: return "Glass"
        case .wallpaper: return "Wallpaper"
        case .color: return "Color"
        case .gradient: return "Gradient"
        }
    }
}

extension NSColor {

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#FFFFFF" }
        let red = Int(round(rgb.redComponent * 255))
        let green = Int(round(rgb.greenComponent * 255))
        let blue = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }

        self.init(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
