import AppKit

/// Full-screen blur overlay simulating the lid-closing effect.
/// macOS exposes no continuous clamshell angle, so `progress`
/// (0 = lid open / no blur, 1 = lid closed / full blur) is driven either by a
/// timed animation on sleep/wake, or by hand from the lid simulator panel.
final class OverlayWindowController {

    private struct Overlay {
        let window: NSWindow
        let effectView: NSVisualEffectView
        let tintView: NSView
        let gradientMask: CAGradientLayer
    }

    private var overlays: [Overlay] = []
    private var hideWorkItem: DispatchWorkItem?

    private(set) var progress: CGFloat = 0

    /// Height of the soft transition band as a fraction of the screen: higher = softer.
    var softness: CGFloat = 0.9 {
        didSet { apply(progress: progress, duration: 0) }
    }

    /// Blur strength once the lid is fully closed.
    var intensity: CGFloat = 1 {
        didSet { apply(progress: progress, duration: 0) }
    }

    var style: BlurStyle = .adaptive {
        didSet {
            overlays.forEach {
                $0.effectView.material = style.material
                $0.effectView.appearance = style.appearance
            }
        }
    }

    /// nil leaves the blur untinted.
    var tint: NSColor? {
        didSet { applyTint() }
    }

    var tintStrength: CGFloat = 0.3 {
        didSet { applyTint() }
    }

    private func applyTint() {
        let color = tint?.withAlphaComponent(tintStrength).cgColor
        overlays.forEach { $0.tintView.layer?.backgroundColor = color }
    }

    init() {
        buildWindows()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildForScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func rebuildForScreenChange() {
        overlays.forEach { $0.window.orderOut(nil) }
        buildWindows()
        apply(progress: progress, duration: 0)
    }

    private func buildWindows() {
        // MVP: cover only the main (built-in) display, not external monitors.
        guard let screen = NSScreen.main else {
            overlays = []
            return
        }
        overlays = [makeOverlay(for: screen)]
    }

    private func makeOverlay(for screen: NSScreen) -> Overlay {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.alphaValue = 0

        let size = screen.frame.size
        let effectView = NSVisualEffectView(frame: CGRect(origin: .zero, size: size))
        effectView.autoresizingMask = [.width, .height]
        effectView.material = style.material
        effectView.appearance = style.appearance
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true

        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        gradient.colors = Self.maskColors()
        gradient.locations = maskLocations(progress: progress)
        // Unflipped layer space: y = 1 is the top of the screen, y = 0 the bottom.
        // Location 0 of the gradient therefore sits at the top, and the blur front
        // travels downward as `progress` grows.
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.endPoint = CGPoint(x: 0.5, y: 0)
        effectView.layer?.mask = gradient

        // Subview of the effect view, so the gradient mask fades the tint along
        // with the blur instead of leaving a coloured rectangle behind.
        let tintView = NSView(frame: CGRect(origin: .zero, size: size))
        tintView.autoresizingMask = [.width, .height]
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = tint?.withAlphaComponent(tintStrength).cgColor
        effectView.addSubview(tintView)

        window.contentView = effectView

        return Overlay(window: window, effectView: effectView, tintView: tintView, gradientMask: gradient)
    }

    /// - Parameters:
    ///   - duration: 0 updates immediately; a short duration smooths the 1° steps
    ///     the sensor reports, a long one animates a full open/close.
    ///   - timing: linear keeps chained tracking updates from stuttering.
    func setProgress(
        _ newValue: CGFloat,
        duration: TimeInterval = 0,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        let clamped = min(max(newValue, 0), 1)
        progress = clamped

        if clamped > 0 {
            hideWorkItem?.cancel()
            hideWorkItem = nil
            overlays.forEach { $0.window.orderFrontRegardless() }
        } else {
            scheduleHide(after: duration + 0.3)
        }

        apply(progress: clamped, duration: duration, timing: timing)
    }

    /// Hiding is delayed so live lid tracking doesn't thrash window ordering
    /// while hovering around the threshold angle.
    private func scheduleHide(after delay: TimeInterval) {
        hideWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.progress == 0 else { return }
            self.overlays.forEach { $0.window.orderOut(nil) }
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    /// Number of stops used to approximate the S-curve of the transition band.
    private static let bandStops = 15

    /// Fraction of the travel over which the overlay eases in from fully transparent.
    private static let appearanceRamp: CGFloat = 0.12

    /// Alpha ramp following a smootherstep curve: it reaches both ends with zero
    /// slope, so there is no perceptible edge where the blur stops.
    private static func maskColors() -> [CGColor] {
        var colors = [CGColor(gray: 0, alpha: 1)]
        for step in 0...bandStops {
            let t = CGFloat(step) / CGFloat(bandStops)
            let eased = t * t * t * (t * (t * 6 - 15) + 10)
            colors.append(CGColor(gray: 0, alpha: 1 - eased))
        }
        return colors
    }

    private func maskLocations(progress p: CGFloat) -> [NSNumber] {
        let feather = max(softness, 0.05)
        // The band travels past the bottom edge so the last sliver still fades softly.
        let end = p * (1 + feather)
        let start = end - feather
        var locations: [NSNumber] = [0]
        for step in 0...Self.bandStops {
            let t = CGFloat(step) / CGFloat(Self.bandStops)
            let position = min(max(start + (end - start) * t, 0), 1)
            locations.append(NSNumber(value: Double(position)))
        }
        return locations
    }

    private func apply(progress p: CGFloat, duration: TimeInterval, timing: CAMediaTimingFunctionName = .easeInEaseOut) {
        let locations = maskLocations(progress: p)
        let timingFunction = CAMediaTimingFunction(name: timing)

        for overlay in overlays {
            CATransaction.begin()
            if duration > 0 {
                CATransaction.setAnimationDuration(duration)
                CATransaction.setAnimationTimingFunction(timingFunction)
            } else {
                CATransaction.setDisableActions(true)
            }
            overlay.gradientMask.locations = locations
            CATransaction.commit()

            // The downward sweep of the mask carries the progression; the overall
            // alpha only eases in at the very start so the blur never pops in.
            let alpha = intensity * min(p / Self.appearanceRamp, 1)
            if duration > 0 {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = duration
                    context.timingFunction = timingFunction
                    overlay.window.animator().alphaValue = alpha
                }
            } else {
                overlay.window.alphaValue = alpha
            }
        }
    }
}
