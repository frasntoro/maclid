import AppKit
import IconArt

final class StatusBarController: NSObject {

    private let statusItem: NSStatusItem
    private let quickControls: QuickControlsViewController
    private var panel: QuickPanel!

    init(
        settings: EffectSettings,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onPanelVisibilityChange: @escaping (Bool) -> Void
    ) {
        quickControls = QuickControlsViewController(
            settings: settings,
            onOpenSettings: onOpenSettings,
            onQuit: onQuit
        )
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        panel = QuickPanel(
            contentViewController: quickControls,
            onVisibilityChange: onPanelVisibilityChange
        )

        if let button = statusItem.button {
            let glyph = NSImage(cgImage: IconArtwork.menuBarGlyph(size: 36), size: NSSize(width: 18, height: 18))
            glyph.isTemplate = true
            button.image = glyph
            button.target = self
            button.action = #selector(togglePanel)
        }
    }

    func closePanel() {
        panel.close()
    }

    func showPanel() {
        guard let button = statusItem.button else { return }
        quickControls.refresh()
        panel.show(relativeTo: button)
    }

    @objc private func togglePanel() {
        if panel.isVisible || panel.closedJustNow {
            panel.close()
        } else {
            showPanel()
        }
    }
}
