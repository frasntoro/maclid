import AppKit

/// Single source of truth shared by the menu bar popover and the settings
/// window. Every change is persisted and broadcast through `onChange`.
final class EffectSettings {

    private enum Key {
        static let isEnabled = "isEnabled"
        static let intensity = "intensity"
        static let softness = "softness"
        static let motion = "motion"
        static let startAngle = "startAngle"
        static let fullAngle = "fullAngle"
        static let tintSource = "tintSource"
        static let customTint = "customTint"
        static let tintStrength = "tintStrength"
        static let gradientFirst = "gradientFirst"
        static let gradientSecond = "gradientSecond"
        static let gradientDirection = "gradientDirection"
        static let gradientBalance = "gradientBalance"
    }

    var onChange: (() -> Void)?

    var isEnabled: Bool { didSet { didUpdate(Key.isEnabled, isEnabled) } }

    /// Maximum blur strength once the lid is fully closed.
    var intensity: CGFloat { didSet { didUpdate(Key.intensity, Double(intensity)) } }

    /// How soft the motion is; see `OverlayWindowController.softness`.
    var softness: CGFloat { didSet { didUpdate(Key.softness, Double(softness)) } }

    /// Lid angle at which the blur starts: high = as soon as you move the lid,
    /// low = only near the end of the travel.
    var motion: BlurMotion { didSet { didUpdate(Key.motion, motion.rawValue) } }

    var startAngle: Double { didSet { didUpdate(Key.startAngle, startAngle) } }

    /// Lid angle at which the blur reaches full strength.
    var fullAngle: Double { didSet { didUpdate(Key.fullAngle, fullAngle) } }

    var tintSource: TintSource { didSet { didUpdate(Key.tintSource, tintSource.rawValue) } }

    var customTint: NSColor { didSet { didUpdate(Key.customTint, customTint.hexString) } }

    var gradientFirst: NSColor { didSet { didUpdate(Key.gradientFirst, gradientFirst.hexString) } }

    var gradientSecond: NSColor { didSet { didUpdate(Key.gradientSecond, gradientSecond.hexString) } }

    var gradientDirection: GradientDirection { didSet { didUpdate(Key.gradientDirection, gradientDirection.rawValue) } }

    /// Where the two colours meet, from 0 (all second colour) to 1 (all first).
    var gradientBalance: CGFloat { didSet { didUpdate(Key.gradientBalance, Double(gradientBalance)) } }

    var gradient: GradientTint {
        GradientTint(first: gradientFirst, second: gradientSecond, direction: gradientDirection, balance: gradientBalance)
    }

    /// How strongly the tint colours the blur. Kept well below 1: past a point
    /// it stops being a tint and just covers the screen.
    var tintStrength: CGFloat { didSet { didUpdate(Key.tintStrength, Double(tintStrength)) } }

    /// The blur needs some travel between its start and its end, or it would
    /// snap on in a single degree.
    static let minimumAngleGap = 5.0

    /// Moves the start angle, pushing the full angle down ahead of it if needed.
    func setStartAngle(_ angle: Double) {
        startAngle = angle
        if fullAngle > angle - Self.minimumAngleGap {
            fullAngle = max(angle - Self.minimumAngleGap, 0)
        }
    }

    /// Moves the full angle, pushing the start angle up ahead of it if needed.
    func setFullAngle(_ angle: Double) {
        fullAngle = angle
        if startAngle < angle + Self.minimumAngleGap {
            startAngle = angle + Self.minimumAngleGap
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.intensity: 1.0,
            Key.softness: 0.45,
            Key.motion: BlurMotion.mist.rawValue,
            Key.startAngle: 70.0,
            Key.fullAngle: 20.0,
            Key.tintSource: TintSource.glass.rawValue,
            Key.customTint: "#5856D6",
            Key.tintStrength: 0.3,
            Key.gradientFirst: "#AF52DE",
            Key.gradientSecond: "#0A84FF",
            Key.gradientDirection: GradientDirection.vertical.rawValue,
            Key.gradientBalance: 0.5
        ])

        isEnabled = defaults.bool(forKey: Key.isEnabled)
        intensity = CGFloat(defaults.double(forKey: Key.intensity))
        softness = CGFloat(defaults.double(forKey: Key.softness))
        motion = BlurMotion(rawValue: defaults.integer(forKey: Key.motion)) ?? .mist
        startAngle = defaults.double(forKey: Key.startAngle)
        fullAngle = defaults.double(forKey: Key.fullAngle)
        tintSource = TintSource(rawValue: defaults.integer(forKey: Key.tintSource)) ?? .glass
        customTint = NSColor(hexString: defaults.string(forKey: Key.customTint) ?? "") ?? .systemIndigo
        tintStrength = CGFloat(defaults.double(forKey: Key.tintStrength))
        gradientFirst = NSColor(hexString: defaults.string(forKey: Key.gradientFirst) ?? "") ?? .systemPurple
        gradientSecond = NSColor(hexString: defaults.string(forKey: Key.gradientSecond) ?? "") ?? .systemBlue
        gradientDirection = GradientDirection(rawValue: defaults.integer(forKey: Key.gradientDirection)) ?? .vertical
        gradientBalance = CGFloat(defaults.double(forKey: Key.gradientBalance))

        // 1.0 offered the system accent colour as a source. Keep the colour those
        // users were seeing, as a plain colour they can now change.
        if defaults.integer(forKey: Key.tintSource) == TintSource.retiredAccent {
            customTint = NSColor.controlAccentColor.usingColorSpace(.sRGB) ?? .systemBlue
            tintSource = .color
            // Observers don't run during init, so persist by hand.
            defaults.set(customTint.hexString, forKey: Key.customTint)
            defaults.set(tintSource.rawValue, forKey: Key.tintSource)
        }
    }

    private func didUpdate(_ key: String, _ value: Any) {
        defaults.set(value, forKey: key)
        onChange?()
    }
}
