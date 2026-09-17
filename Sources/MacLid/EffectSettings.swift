import AppKit

/// Single source of truth shared by the menu bar popover and the settings
/// window. Every change is persisted and broadcast through `onChange`.
final class EffectSettings {

    private enum Key {
        static let isEnabled = "isEnabled"
        static let intensity = "intensity"
        static let softness = "softness"
        static let startAngle = "startAngle"
        static let fullAngle = "fullAngle"
        static let blurStyle = "blurStyle"
        static let tintSource = "tintSource"
        static let customTint = "customTint"
        static let tintStrength = "tintStrength"
    }

    var onChange: (() -> Void)?

    var isEnabled: Bool { didSet { didUpdate(Key.isEnabled, isEnabled) } }

    /// Maximum blur strength once the lid is fully closed.
    var intensity: CGFloat { didSet { didUpdate(Key.intensity, Double(intensity)) } }

    /// Width of the soft transition band, as a fraction of the screen height.
    var softness: CGFloat { didSet { didUpdate(Key.softness, Double(softness)) } }

    /// Lid angle at which the blur starts: high = as soon as you move the lid,
    /// low = only near the end of the travel.
    var startAngle: Double { didSet { didUpdate(Key.startAngle, startAngle) } }

    /// Lid angle at which the blur reaches full strength.
    var fullAngle: Double { didSet { didUpdate(Key.fullAngle, fullAngle) } }

    var blurStyle: BlurStyle { didSet { didUpdate(Key.blurStyle, blurStyle.rawValue) } }

    var tintSource: TintSource { didSet { didUpdate(Key.tintSource, tintSource.rawValue) } }

    var customTint: NSColor { didSet { didUpdate(Key.customTint, customTint.hexString) } }

    /// How strongly the tint colours the blur. Kept well below 1: past a point
    /// it stops being a tint and just covers the screen.
    var tintStrength: CGFloat { didSet { didUpdate(Key.tintStrength, Double(tintStrength)) } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.intensity: 1.0,
            Key.softness: 0.45,
            Key.startAngle: 70.0,
            Key.fullAngle: 20.0,
            Key.blurStyle: BlurStyle.adaptive.rawValue,
            Key.tintSource: TintSource.none.rawValue,
            Key.customTint: "#5856D6",
            Key.tintStrength: 0.3
        ])

        isEnabled = defaults.bool(forKey: Key.isEnabled)
        intensity = CGFloat(defaults.double(forKey: Key.intensity))
        softness = CGFloat(defaults.double(forKey: Key.softness))
        startAngle = defaults.double(forKey: Key.startAngle)
        fullAngle = defaults.double(forKey: Key.fullAngle)
        blurStyle = BlurStyle(rawValue: defaults.integer(forKey: Key.blurStyle)) ?? .adaptive
        tintSource = TintSource(rawValue: defaults.integer(forKey: Key.tintSource)) ?? .none
        customTint = NSColor(hexString: defaults.string(forKey: Key.customTint) ?? "") ?? .systemIndigo
        tintStrength = CGFloat(defaults.double(forKey: Key.tintStrength))
    }

    private func didUpdate(_ key: String, _ value: Any) {
        defaults.set(value, forKey: key)
        onChange?()
    }
}
