import AppKit

final class StatusBarController {

    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let quickControls: QuickControlsViewController

    init(settings: EffectSettings, onOpenSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        quickControls = QuickControlsViewController(
            settings: settings,
            onOpenSettings: onOpenSettings,
            onQuit: onQuit
        )

        popover.contentViewController = quickControls
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "moon.haze.fill", accessibilityDescription: "MacLid")
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        quickControls.refresh()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }
}
