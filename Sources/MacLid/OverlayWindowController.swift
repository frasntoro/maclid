import AppKit

/// Full-screen blur overlay for the lid-closing effect. `progress` (0 = lid
/// open / no blur, 1 = lid closed / full blur) follows the lid angle sensor
/// where there is one, a timed animation on sleep and wake where there isn't,
/// or the preview controls in the settings.
final class OverlayWindowController {

    private struct Overlay {
        let window: NSWindow
        let effectView: NSVisualEffectView
        let tintView: NSView
        let tintLayer: CAGradientLayer
        let gradientMask: CAGradientLayer
    }

    private var overlays: [Overlay] = []
    private var hideWorkItem: DispatchWorkItem?

    /// Held down while the popover is open. A popover is translucent and samples
    /// whatever is behind it, so an active overlay would tint the very controls
    /// used to adjust it — and raising the popover instead breaks its anchoring
    /// and its click-outside dismissal.
    var isSuppressed = false {
        didSet {
            guard isSuppressed != oldValue else { return }

            if !isSuppressed, progress > 0 {
                hideWorkItem?.cancel()
                overlays.forEach { $0.window.orderFrontRegardless() }
            }
            apply(progress: progress, duration: 0.2)
            if isSuppressed {
                scheduleHide(after: 0.25)
            }
        }
    }

    private(set) var progress: CGFloat = 0

    /// Shapes the motion: how far ahead the top stays for Mist, how wide the
    /// front is, as a fraction of the screen, for Curtain. Higher = softer.
    var softness: CGFloat = 0.45 {
        didSet { apply(progress: progress, duration: 0) }
    }

    var motion: BlurMotion = .mist {
        didSet { apply(progress: progress, duration: 0) }
    }

    /// Blur strength once the lid is fully closed.
    var intensity: CGFloat = 1 {
        didSet { apply(progress: progress, duration: 0) }
    }

    /// nil leaves the blur untinted.
    var tint: GradientTint? {
        didSet { applyTint() }
    }

    var tintStrength: CGFloat = 0.3 {
        didSet { applyTint() }
    }

    private func applyTint() {
        overlays.forEach(configureTint)
    }

    private func configureTint(of overlay: Overlay) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlay.tintLayer.isHidden = tint == nil
        tint?.apply(to: overlay.tintLayer, alpha: tintStrength)
        CATransaction.commit()
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
        // A clear, dark glass: the one look of the old styles that read as
        // glass rather than as a grey or white veil, and the only one kept.
        effectView.material = .fullScreenUI
        effectView.appearance = NSAppearance(named: .darkAqua)
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true

        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        gradient.colors = maskColors(progress: progress)
        gradient.locations = Self.maskLocations
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
        effectView.addSubview(tintView)

        let tintLayer = CAGradientLayer()
        tintLayer.frame = tintView.bounds
        tintLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        tintView.layer?.addSublayer(tintLayer)

        window.contentView = effectView

        let overlay = Overlay(window: window, effectView: effectView, tintView: tintView, tintLayer: tintLayer, gradientMask: gradient)
        configureTint(of: overlay)
        return overlay
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
        let previous = progress
        progress = clamped

        if clamped > 0 {
            hideWorkItem?.cancel()
            hideWorkItem = nil
            overlays.forEach { $0.window.orderFrontRegardless() }
        } else {
            scheduleHide(after: duration + 0.3)
        }

        apply(from: previous, progress: clamped, duration: duration, timing: timing)
    }

    /// Hiding is delayed so live lid tracking doesn't thrash window ordering
    /// while hovering around the threshold angle.
    private func scheduleHide(after delay: TimeInterval) {
        hideWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.progress == 0 || self.isSuppressed else { return }
            self.overlays.forEach { $0.window.orderOut(nil) }
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    // MARK: The mask
    //
    // Both motions are a function giving the blur's opacity at each row of
    // the screen for a given progress; the mask samples it at evenly spaced
    // rows. Mist: every row mists over on its own, the top a little ahead of
    // the bottom, with no line that visibly slides. Curtain: a soft front
    // descends from the top edge.

    /// Rows the mask is sampled at, evenly from the top edge to the bottom.
    /// Dense enough for the curtain's narrowest front to keep its S-curve.
    private static let maskStops = 64

    private static let maskLocations: [NSNumber] = (0...maskStops).map {
        NSNumber(value: Double($0) / Double(maskStops))
    }

    /// Head start given to every row, as a share of its own fade: the top is
    /// visibly misting over from the first degrees instead of waiting.
    private static let rowLead: CGFloat = 0.3

    /// Share of the travel over which the whole mask eases in from nothing,
    /// so with the lid open the screen is untouched, whatever the head start.
    private static let entryRamp: CGFloat = 0.2

    /// How much of the travel each row takes to fade in. Softness lengthens
    /// it, which shrinks the lag between top and bottom: low softness, the
    /// top clearly leads; high, the screen mists over almost as one — but the
    /// lag never goes to zero, so it always starts from the top.
    private var rowSpan: CGFloat {
        min(0.5 + 0.13 * max(softness, 0), 0.8)
    }

    /// Opacity of the blur at a row (0 = top edge, 1 = bottom) for a progress.
    private func maskAlpha(row y: CGFloat, progress p: CGFloat) -> CGFloat {
        switch motion {
        case .mist: return mistAlpha(row: y, progress: p)
        case .curtain: return curtainAlpha(row: y, progress: p)
        }
    }

    private func mistAlpha(row y: CGFloat, progress p: CGFloat) -> CGFloat {
        let span = rowSpan
        let lag = 1 - span
        let t = min(max((p - lag * y + Self.rowLead * span * (1 - p)) / span, 0), 1)
        let row = t * t * (3 - 2 * t)

        let e = min(max(p / Self.entryRamp, 0), 1)
        let entry = 1 - (1 - e) * (1 - e)
        return row * entry
    }

    /// Share of the curtain taken by its fading front while the front is still
    /// growing; the rest, nearest the top edge, is fully blurred.
    private static let curtainFrontShare: CGFloat = 0.85

    /// Share of the travel over which the curtain builds to full intensity.
    private static let curtainEntry: CGFloat = 0.28

    /// The front's leading edge descends from the top and travels past the
    /// bottom, so the last sliver still fades softly. Softness sets the width
    /// of the front, but it can't be wider than the distance travelled: in the
    /// first degrees the curtain is a narrow strip growing out of the top
    /// edge, instead of the faint tail of a front still mostly off screen.
    private func curtainAlpha(row y: CGFloat, progress p: CGFloat) -> CGFloat {
        let softness = max(self.softness, 0.05)
        let end = p * (1 + softness)
        let front = min(softness, end * Self.curtainFrontShare)
        let start = end - front

        let row: CGFloat
        if y <= start {
            row = 1
        } else if y >= end || front <= 0 {
            row = 0
        } else {
            let t = (y - start) / front
            row = 1 - t * t * t * (t * (t * 6 - 15) + 10)
        }

        let e = min(max(p / Self.curtainEntry, 0), 1)
        return row * (1 - (1 - e) * (1 - e))
    }

    private func maskColors(progress p: CGFloat) -> [CGColor] {
        (0...Self.maskStops).map { step in
            let y = CGFloat(step) / CGFloat(Self.maskStops)
            return CGColor(gray: 0, alpha: maskAlpha(row: y, progress: p))
        }
    }

    /// Frames per second of travel for animated changes. Core Animation would
    /// otherwise blend the start and end masks directly, which is a flat fade
    /// that loses the top-first shape along the way.
    private static let keyframesPerSecond = 30.0

    private func apply(
        from oldProgress: CGFloat? = nil,
        progress p: CGFloat,
        duration: TimeInterval,
        timing: CAMediaTimingFunctionName = .easeInEaseOut
    ) {
        let colors = maskColors(progress: p)
        let timingFunction = CAMediaTimingFunction(name: timing)

        var animation: CAKeyframeAnimation?
        if duration > 0, let from = oldProgress, from != p {
            let frames = max(Int((duration * Self.keyframesPerSecond).rounded()), 2)
            let keyframe = CAKeyframeAnimation(keyPath: "colors")
            keyframe.values = (0...frames).map { index -> [CGColor] in
                let t = Float(index) / Float(frames)
                let eased = CGFloat(timingFunction.value(at: t))
                return maskColors(progress: from + (p - from) * eased)
            }
            keyframe.duration = duration
            keyframe.calculationMode = .linear
            animation = keyframe
        }

        for overlay in overlays {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            overlay.gradientMask.colors = colors
            if let animation {
                overlay.gradientMask.add(animation, forKey: "progress")
            } else {
                overlay.gradientMask.removeAnimation(forKey: "progress")
            }
            CATransaction.commit()

            // The mask carries the whole progression, fading in from nothing;
            // the window only applies the intensity, and hides while suppressed.
            let alpha = isSuppressed ? 0 : intensity
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

private extension CAMediaTimingFunction {

    /// The eased output for an input time, found by bisecting the Bézier's x.
    func value(at time: Float) -> Float {
        var c1: [Float] = [0, 0], c2: [Float] = [0, 0]
        getControlPoint(at: 1, values: &c1)
        getControlPoint(at: 2, values: &c2)

        func bezier(_ t: Float, _ a: Float, _ b: Float) -> Float {
            let u = 1 - t
            return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t
        }

        var low: Float = 0, high: Float = 1, t = time
        for _ in 0..<20 {
            t = (low + high) / 2
            if bezier(t, c1[0], c2[0]) < time { low = t } else { high = t }
        }
        return bezier(t, c1[1], c2[1])
    }
}
