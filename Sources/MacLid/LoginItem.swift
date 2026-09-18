import Foundation
import ServiceManagement

/// Launch at login, via the modern SMAppService registration.
enum LoginItem {

    /// Registration is keyed to the app bundle, so it can't work while running
    /// the bare executable from `swift run`.
    static var isAvailable: Bool {
        guard #available(macOS 13, *) else { return false }
        return Bundle.main.bundleURL.pathExtension == "app"
    }

    static var isEnabled: Bool {
        guard #available(macOS 13, *), isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard #available(macOS 13, *), isAvailable else { return false }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
