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
    private let tabController = FittingTabViewController()
    private let effectTab: EffectTabViewController
    private let lidTab: LidTabViewController
    private weak var delegate: SettingsWindowDelegate?

    init(settings: EffectSettings, sensorAvailable: Bool, followsLid: Bool, delegate: SettingsWindowDelegate) {
        self.delegate = delegate

        effectTab = EffectTabViewController(settings: settings)
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
        tabController.addTabViewItem(Self.item(GeneralTabViewController(), title: "General", symbol: "gearshape"))
        tabController.addTabViewItem(Self.item(effectTab, title: "Effect", symbol: "circle.lefthalf.filled"))
        tabController.addTabViewItem(Self.item(lidTab, title: "Lid", symbol: "laptopcomputer"))
        tabController.addTabViewItem(Self.item(aboutTab, title: "About", symbol: "info.circle"))

        window.title = AppInfo.name
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentViewController = tabController
        // Kept above the overlay so the controls stay readable while tuning.
        window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        // Otherwise it opens on the Space the app was launched from.
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        tabController.fitWindowToSelectedTab(animate: false)
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

    /// The menu bar panel edits the same settings while this window may be open.
    func refresh() {
        effectTab.refresh()
        lidTab.refresh()
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

/// NSTabViewController keeps the window at the size of the tallest tab seen so
/// far, which leaves short tabs floating in empty space. This one sizes the
/// window to each tab's content, keeping the top edge where it was.
final class FittingTabViewController: NSTabViewController {

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        fitWindowToSelectedTab(animate: true)
    }

    func fitWindowToSelectedTab(animate: Bool) {
        guard selectedTabViewItemIndex >= 0,
              let content = tabViewItems[selectedTabViewItemIndex].viewController?.view,
              let window = view.window
        else { return }

        content.layoutSubtreeIfNeeded()
        let height = content.fittingSize.height
        let contentRect = window.contentRect(forFrameRect: window.frame)
        guard abs(contentRect.height - height) > 0.5 else { return }

        var frame = window.frameRect(forContentRect: NSRect(x: contentRect.minX, y: contentRect.minY, width: contentRect.width, height: height))
        frame.origin.y = window.frame.maxY - frame.height
        window.setFrame(frame, display: true, animate: animate && window.isVisible)
    }
}
