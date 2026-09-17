import AppKit

/// Presets pairing a system material with the appearance variant that makes it
/// look right. Apple names materials after where they are used, not after how
/// they look, so those names aren't worth putting in front of anyone.
enum BlurStyle: Int, CaseIterable {
    case adaptive
    case light
    case dark
    case smoke

    var material: NSVisualEffectView.Material {
        switch self {
        case .adaptive, .light, .dark: return .fullScreenUI
        case .smoke: return .hudWindow
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .adaptive: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark, .smoke: return NSAppearance(named: .darkAqua)
        }
    }

    var label: String {
        switch self {
        case .adaptive: return "Adaptive"
        case .light: return "Light"
        case .dark: return "Dark"
        case .smoke: return "Smoke"
        }
    }
}
