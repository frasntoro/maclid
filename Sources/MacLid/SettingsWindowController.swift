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
    private var isPreviewing = false
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
        // An ordinary window, except while previewing the effect by hand: see
        // `setPreviewing`.
        window.level = .normal
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
        endColorEditing()
        window.close()
    }

    /// The colour panel isn't part of this window, so it outlives it unless
    /// told otherwise, still wired to a colour well nobody can see.
    private func endColorEditing() {
        effectTab.deactivateColorWells()
        if NSColorPanel.sharedColorPanelExists {
            NSColorPanel.shared.close()
        }
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

    /// Just above the overlay, which sits at `.screenSaver`.
    private static let floatingLevel = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)

    /// The overlay covers the whole screen, so while the effect is being
    /// driven by hand from the Lid tab the window has to sit above it or the
    /// controls disappear under what they are controlling. That is the only
    /// reason to leave the ordinary window order, and it lasts only as long as
    /// the preview does: pinned above everything, the window could never be
    /// put behind another app, and a menu bar app's window that goes missing
    /// is hard to get back.
    func setPreviewing(_ previewing: Bool) {
        isPreviewing = previewing
        updateLevel()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        updateLevel()
    }

    func windowDidResignKey(_ notification: Notification) {
        updateLevel()
    }

    private func updateLevel() {
        let level: NSWindow.Level = isPreviewing && window.isKeyWindow ? Self.floatingLevel : .normal
        window.level = level
        // The colour panel belongs to the app, not to this window, and floats
        // at its own level: below this one when raised, above everything when
        // not.
        if NSColorPanel.sharedColorPanelExists {
            NSColorPanel.shared.level = level == .normal ? .floating : level
        }
    }

    func windowWillClose(_ notification: Notification) {
        endColorEditing()
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
