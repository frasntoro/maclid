import AppKit

/// Menu bar panel in the shape macOS uses for its own: no arrow, edge-aligned
/// under the status item, rounded corners over a vibrant background.
/// `NSPopover` can't do this — it always centres on its anchor and always draws
/// the arrow — so the window, the placement and the dismissal are hand-rolled.
final class QuickPanel: NSObject, NSWindowDelegate {

    private final class KeyablePanel: NSPanel {
        override var canBecomeKey: Bool { true }

        override func cancelOperation(_ sender: Any?) {
            close()
        }
    }

    private let panel: KeyablePanel
    private let contentViewController: NSViewController
    private let onVisibilityChange: (Bool) -> Void

    private var lastClose = Date.distantPast

    var isVisible: Bool { panel.isVisible }

    /// Clicking the status item while the panel is open makes it resign key and
    /// close before the button's action runs, which would immediately reopen it.
    var closedJustNow: Bool { Date().timeIntervalSince(lastClose) < 0.25 }

    init(contentViewController: NSViewController, onVisibilityChange: @escaping (Bool) -> Void) {
        self.contentViewController = contentViewController
        self.onVisibilityChange = onVisibilityChange

        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        panel.contentView = makeBackground()
    }

    private func makeBackground() -> NSView {
        let background = NSVisualEffectView()
        background.material = .popover
        background.state = .active
        background.blendingMode = .behindWindow
        // A layer corner radius doesn't clip the material itself, which leaves
        // pale fringes at the corners; maskImage is the supported way.
        background.maskImage = Self.roundedMask(radius: 13)

        let content = contentViewController.view
        content.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            content.topAnchor.constraint(equalTo: background.topAnchor),
            content.bottomAnchor.constraint(equalTo: background.bottomAnchor)
        ])
        return background
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }

        let size = contentViewController.view.fittingSize
        panel.setContentSize(size)

        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = buttonWindow.screen ?? NSScreen.main
        panel.setFrameOrigin(origin(for: size, anchor: anchor, screen: screen))

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }
        onVisibilityChange(true)
    }

    /// Left edge under the status item, flipping to the right edge when the
    /// panel would otherwise run past the screen.
    private func origin(for size: NSSize, anchor: NSRect, screen: NSScreen?) -> NSPoint {
        let margin: CGFloat = 8
        var x = anchor.minX

        if let visible = screen?.visibleFrame {
            if x + size.width > visible.maxX - margin {
                x = anchor.maxX - size.width
            }
            x = min(max(x, visible.minX + margin), visible.maxX - margin - size.width)
        }
        return NSPoint(x: x, y: anchor.minY - size.height - 6)
    }

    func close() {
        guard panel.isVisible else { return }
        lastClose = Date()
        panel.orderOut(nil)
        onVisibilityChange(false)
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }
}
