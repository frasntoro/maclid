import AppKit

protocol SettingsWindowDelegate: AnyObject {
    func settingsWindow(didSetFollowsLid follows: Bool)
    func settingsWindow(didScrubTo progress: CGFloat)
    func settingsWindow(didRequestAnimationTo target: CGFloat)
    func settingsWindowWillClose()
}

/// Tabbed settings window, in the shape macOS users expect from a preferences
/// window: one tab per question — how it looks, when it fires, what it is.
final class SettingsWindowController: NSObject, NSWindowDelegate {

    private let window: NSWindow
    private let tabController = NSTabViewController()
    private let lidTab: LidTabViewController
    private weak var delegate: SettingsWindowDelegate?

    init(settings: EffectSettings, sensorAvailable: Bool, followsLid: Bool, delegate: SettingsWindowDelegate) {
        self.delegate = delegate

        let effectTab = EffectTabViewController(settings: settings)
        lidTab = LidTabViewController(
            settings: settings,
            sensorAvailable: sensorAvailable,
            followsLid: followsLid,
            delegate: nil
        )
        let aboutTab = AboutTabViewController(sensorAvailable: sensorAvailable)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        super.init()

        lidTab.delegate = self

        tabController.tabStyle = .toolbar
        tabController.addTabViewItem(Self.item(effectTab, title: "Effect", symbol: "circle.lefthalf.filled"))
        tabController.addTabViewItem(Self.item(lidTab, title: "Lid", symbol: "laptopcomputer"))
        tabController.addTabViewItem(Self.item(aboutTab, title: "About", symbol: "info.circle"))

        window.title = AppInfo.name
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentViewController = tabController
        // Kept above the overlay so the controls stay readable while tuning.
        window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        window.center()
    }

    private static func item(_ controller: NSViewController, title: String, symbol: String) -> NSTabViewItem {
        let item = NSTabViewItem(viewController: controller)
        item.label = title
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        return item
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window.delegate = nil
        window.close()
    }

    func updateMeasuredAngle(_ angle: Double) {
        lidTab.updateMeasuredAngle(angle)
    }

    func updateProgressReadout(_ progress: CGFloat) {
        lidTab.updateProgressReadout(progress)
    }

    func windowWillClose(_ notification: Notification) {
        delegate?.settingsWindowWillClose()
    }
}

extension SettingsWindowController: LidTabDelegate {

    func lidTab(didSetFollowsLid follows: Bool) {
        delegate?.settingsWindow(didSetFollowsLid: follows)
    }

    func lidTab(didScrubTo progress: CGFloat) {
        delegate?.settingsWindow(didScrubTo: progress)
    }

    func lidTab(didRequestAnimationTo target: CGFloat) {
        delegate?.settingsWindow(didRequestAnimationTo: target)
    }
}
