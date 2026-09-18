import AppKit

/// The shape a two-colour tint takes across the screen.
enum GradientDirection: Int, CaseIterable {
    case vertical
    case diagonal
    case horizontal
    case radial

    var label: String {
        switch self {
        case .vertical: return "Top to bottom"
        case .diagonal: return "Diagonal"
        case .horizontal: return "Side to side"
        case .radial: return "From the center"
        }
    }
}

/// Two colours, how they're laid out, and where they meet. Shared by the
/// overlay and the preview in the settings, so what you see there is what
/// lands on the screen.
struct GradientTint {
    var first: NSColor
    var second: NSColor
    var direction: GradientDirection
    /// Where the two colours meet half and half: 0 is the start of the
    /// gradient, 1 its end. Moving it gives more room to one colour.
    var balance: CGFloat

    func apply(to layer: CAGradientLayer, alpha: CGFloat) {
        let start = first.usingColorSpace(.sRGB) ?? first
        let end = second.usingColorSpace(.sRGB) ?? second
        let middle = start.blended(withFraction: 0.5, of: end) ?? start

        layer.colors = [start, middle, end].map { $0.withAlphaComponent(alpha).cgColor }
        layer.locations = [0, NSNumber(value: Double(min(max(balance, 0.05), 0.95))), 1]

        // Unflipped layer space: y = 1 is the top edge.
        switch direction {
        case .vertical:
            layer.type = .axial
            layer.startPoint = CGPoint(x: 0.5, y: 1)
            layer.endPoint = CGPoint(x: 0.5, y: 0)
        case .diagonal:
            layer.type = .axial
            layer.startPoint = CGPoint(x: 0, y: 1)
            layer.endPoint = CGPoint(x: 1, y: 0)
        case .horizontal:
            layer.type = .axial
            layer.startPoint = CGPoint(x: 0, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 0.5)
        case .radial:
            layer.type = .radial
            layer.startPoint = CGPoint(x: 0.5, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 1)
        }
    }

    /// A single colour, drawn through the same path as a gradient.
    static func solid(_ color: NSColor) -> GradientTint {
        GradientTint(first: color, second: color, direction: .vertical, balance: 0.5)
    }
}

/// A small swatch of the gradient for the settings window.
final class GradientPreviewView: NSView {

    private let gradientLayer = CAGradientLayer()

    var tint: GradientTint? {
        didSet { update() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.addSublayer(gradientLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }

    override func updateLayer() {
        layer?.borderColor = NSColor.separatorColor.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    private func update() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tint?.apply(to: gradientLayer, alpha: 1)
        CATransaction.commit()
    }
}
