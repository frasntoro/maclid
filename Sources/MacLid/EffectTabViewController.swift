import AppKit

/// "Effetto" tab: how the blur looks, independent of when it triggers.
final class EffectTabViewController: NSViewController {

    private let settings: EffectSettings

    private var intensitySlider: NSSlider!
    private var softnessSlider: NSSlider!
    private let motionControl = NSSegmentedControl(
        labels: BlurMotion.allCases.map(\.label),
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let motionCaption = ControlFactory.caption("")
    private let tintSourcePopup = NSPopUpButton()
    private let tintWell = NSColorWell()
    private let gradientFirstWell = NSColorWell()
    private let gradientSecondWell = NSColorWell()
    private let gradientPreview = GradientPreviewView()
    private let directionPopup = NSPopUpButton()
    private var mixSlider: NSSlider!
    private let mixValueLabel = NSTextField(labelWithString: "")
    private let colorCaption = ControlFactory.caption("")
    private var colorRow: NSView!
    private var gradientRows: [NSView] = []
    private var strengthRow: NSView!
    private var tintStrengthSlider: NSSlider!
    private let tintStrengthValueLabel = NSTextField(labelWithString: "")
    private let intensityValueLabel = NSTextField(labelWithString: "")
    private let softnessValueLabel = NSTextField(labelWithString: "")

    init(settings: EffectSettings) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        intensitySlider = ControlFactory.slider(min: 0.2, max: 1, value: Double(settings.intensity), target: self, action: #selector(intensityChanged))
        softnessSlider = ControlFactory.slider(min: 0.05, max: 2.5, value: Double(settings.softness), target: self, action: #selector(softnessChanged))

        motionControl.target = self
        motionControl.action = #selector(motionChanged)

        tintSourcePopup.addItems(withTitles: TintSource.allCases.map(\.label))
        tintSourcePopup.target = self
        tintSourcePopup.action = #selector(tintSourceChanged)

        directionPopup.addItems(withTitles: GradientDirection.allCases.map(\.label))
        directionPopup.target = self
        directionPopup.action = #selector(directionChanged)

        mixSlider = ControlFactory.slider(min: 0.05, max: 0.95, value: Double(settings.gradientBalance), target: self, action: #selector(mixChanged))

        // Shaped like the screen, so a diagonal or a radial gradient reads as it will there.
        let screenSize = NSScreen.main?.frame.size ?? NSSize(width: 16, height: 10)
        let previewWidth: CGFloat = 176
        gradientPreview.widthAnchor.constraint(equalToConstant: previewWidth).isActive = true
        gradientPreview.heightAnchor.constraint(equalToConstant: (previewWidth * screenSize.height / screenSize.width).rounded()).isActive = true

        let swapButton = NSButton(
            image: NSImage(systemSymbolName: "arrow.left.arrow.right", accessibilityDescription: "Swap colors")!,
            target: self,
            action: #selector(swapColors)
        )
        swapButton.isBordered = false
        swapButton.contentTintColor = .secondaryLabelColor
        swapButton.toolTip = "Swap the two colors"

        for well in [tintWell, gradientFirstWell, gradientSecondWell] {
            well.target = self
            well.action = #selector(colorWellChanged(_:))
        }

        tintStrengthSlider = ControlFactory.slider(min: 0.05, max: 0.7, value: Double(settings.tintStrength), target: self, action: #selector(tintStrengthChanged))

        colorRow = ControlFactory.popupRow("Color", Self.wellRow(tintWell))
        let colorsRow = NSStackView(views: [
            Self.sizedWell(gradientFirstWell),
            swapButton,
            Self.sizedWell(gradientSecondWell),
            NSView()
        ])
        colorsRow.orientation = .horizontal
        colorsRow.spacing = 10

        gradientRows = [
            ControlFactory.popupRow("Colors", colorsRow),
            ControlFactory.popupRow("Direction", directionPopup),
            ControlFactory.row("Mix", mixSlider, mixValueLabel),
            ControlFactory.popupRow("Preview", ControlFactory.leading(gradientPreview))
        ]
        strengthRow = ControlFactory.row("Strength", tintStrengthSlider, tintStrengthValueLabel)

        let stack = NSStackView(views: [
            ControlFactory.sectionTitle("Blur"),
            ControlFactory.popupRow("Style", ControlFactory.leading(motionControl)),
            ControlFactory.row("Intensity", intensitySlider, intensityValueLabel),
            ControlFactory.row("Softness", softnessSlider, softnessValueLabel),
            motionCaption,
            ControlFactory.separator(),
            ControlFactory.sectionTitle("Color"),
            ControlFactory.popupRow("Tint", tintSourcePopup),
            colorRow
        ] + gradientRows + [
            strengthRow,
            colorCaption
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        view = ControlFactory.container(for: stack)
        refresh()
    }

    func deactivateColorWells() {
        [tintWell, gradientFirstWell, gradientSecondWell].forEach { $0.deactivate() }
    }

    /// Pulls every control back in line with the settings, which the menu bar
    /// panel can change while this tab is open.
    func refresh() {
        guard isViewLoaded else { return }
        intensitySlider.doubleValue = Double(settings.intensity)
        softnessSlider.doubleValue = Double(settings.softness)
        motionControl.selectedSegment = settings.motion.rawValue
        tintSourcePopup.selectItem(at: TintSource.allCases.firstIndex(of: settings.tintSource) ?? 0)
        tintWell.color = settings.customTint
        gradientFirstWell.color = settings.gradientFirst
        gradientSecondWell.color = settings.gradientSecond
        directionPopup.selectItem(at: settings.gradientDirection.rawValue)
        mixSlider.doubleValue = Double(settings.gradientBalance)
        tintStrengthSlider.doubleValue = Double(settings.tintStrength)
        refreshLabels()
    }

    /// The well keeps its natural size instead of stretching across the row.
    private static func wellRow(_ well: NSColorWell) -> NSStackView {
        ControlFactory.leading(sizedWell(well))
    }

    private static func sizedWell(_ well: NSColorWell) -> NSColorWell {
        well.widthAnchor.constraint(equalToConstant: 64).isActive = true
        return well
    }

    private func refreshLabels() {
        intensityValueLabel.stringValue = ControlFactory.percent(settings.intensity)
        softnessValueLabel.stringValue = ControlFactory.percent(settings.softness)
        tintStrengthValueLabel.stringValue = ControlFactory.percent(settings.tintStrength)
        let firstShare = Int((settings.gradientBalance * 100).rounded())
        mixValueLabel.stringValue = "\(firstShare):\(100 - firstShare)"
        gradientPreview.tint = settings.gradient

        // Only the controls for the chosen source are shown; the stack closes the gaps.
        let source = settings.tintSource
        // A well left active behind a hidden row would keep the colour panel
        // editing a colour that is no longer in use.
        if source != .color { tintWell.deactivate() }
        if source != .gradient { [gradientFirstWell, gradientSecondWell].forEach { $0.deactivate() } }
        colorRow.isHidden = source != .color
        gradientRows.forEach { $0.isHidden = source != .gradient }
        strengthRow.isHidden = source == .glass
        colorCaption.stringValue = Self.caption(for: source)
        motionCaption.stringValue = Self.caption(for: settings.motion)
        fitWindowToContent()
    }

    /// Rows come and go with the tint source; the window follows, growing or
    /// shrinking from the bottom so the toolbar stays where it was.
    private func fitWindowToContent() {
        guard let window = view.window else { return }
        view.layoutSubtreeIfNeeded()
        let delta = view.fittingSize.height - view.frame.height
        guard abs(delta) > 0.5 else { return }

        var frame = window.frame
        frame.size.height += delta
        frame.origin.y -= delta
        window.setFrame(frame, display: true, animate: window.isVisible)
    }

    private static func caption(for motion: BlurMotion) -> String {
        switch motion {
        case .mist:
            return "The screen mists over from the top down. Softness sets how far ahead the top stays: low, you clearly see it coming down; high, the whole screen blurs almost together."
        case .curtain:
            return "A soft front comes down from the top, like a curtain. Softness sets how wide the front is: low, a clear edge sweeps down; high, a long fade."
        }
    }

    private static func caption(for source: TintSource) -> String {
        switch source {
        case .glass:
            return "A clear glass blur, with no color on it."
        case .wallpaper:
            return "Takes the color of your desktop picture, weighted so grey areas don't dull it. It needs the picture's file to still be on disk."
        case .color:
            return "One color, evenly across the blur."
        case .gradient:
            return "Mix moves the point where the two colors meet, giving more room to one or the other."
        }
    }

    @objc private func intensityChanged() {
        settings.intensity = CGFloat(intensitySlider.doubleValue)
        refreshLabels()
    }

    @objc private func motionChanged() {
        settings.motion = BlurMotion(rawValue: motionControl.selectedSegment) ?? .mist
        refreshLabels()
    }

    @objc private func softnessChanged() {
        settings.softness = CGFloat(softnessSlider.doubleValue)
        refreshLabels()
    }

    @objc private func tintSourceChanged() {
        settings.tintSource = TintSource.allCases[tintSourcePopup.indexOfSelectedItem]
        refreshLabels()
    }

    @objc private func directionChanged() {
        settings.gradientDirection = GradientDirection(rawValue: directionPopup.indexOfSelectedItem) ?? .vertical
    }

    @objc private func mixChanged() {
        settings.gradientBalance = CGFloat(mixSlider.doubleValue)
    }

    @objc private func swapColors() {
        let first = settings.gradientFirst
        settings.gradientFirst = settings.gradientSecond
        settings.gradientSecond = first
        // Mirrored too, so swapping flips the gradient instead of reshaping it.
        settings.gradientBalance = 1 - settings.gradientBalance
    }

    @objc private func colorWellChanged(_ well: NSColorWell) {
        switch well {
        case gradientFirstWell: settings.gradientFirst = well.color
        case gradientSecondWell: settings.gradientSecond = well.color
        default: settings.customTint = well.color
        }
    }

    @objc private func tintStrengthChanged() {
        settings.tintStrength = CGFloat(tintStrengthSlider.doubleValue)
        refreshLabels()
    }
}
