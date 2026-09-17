import AppKit

/// "Effetto" tab: how the blur looks, independent of when it triggers.
final class EffectTabViewController: NSViewController {

    private let settings: EffectSettings

    private var intensitySlider: NSSlider!
    private var softnessSlider: NSSlider!
    private let stylePopup = NSPopUpButton()
    private let tintSourcePopup = NSPopUpButton()
    private let tintWell = NSColorWell()
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

        stylePopup.addItems(withTitles: BlurStyle.allCases.map(\.label))
        stylePopup.selectItem(at: settings.blurStyle.rawValue)
        stylePopup.target = self
        stylePopup.action = #selector(styleChanged)

        tintSourcePopup.addItems(withTitles: TintSource.allCases.map(\.label))
        tintSourcePopup.selectItem(at: settings.tintSource.rawValue)
        tintSourcePopup.target = self
        tintSourcePopup.action = #selector(tintSourceChanged)

        tintWell.color = settings.customTint
        tintWell.target = self
        tintWell.action = #selector(tintColorChanged)

        tintStrengthSlider = ControlFactory.slider(min: 0.05, max: 0.7, value: Double(settings.tintStrength), target: self, action: #selector(tintStrengthChanged))

        let stack = NSStackView(views: [
            ControlFactory.sectionTitle("Blur"),
            ControlFactory.row("Intensity", intensitySlider, intensityValueLabel),
            ControlFactory.row("Softness", softnessSlider, softnessValueLabel),
            ControlFactory.caption("Softness widens the fading band: the higher it is, the harder it is to tell where the blur ends."),
            ControlFactory.separator(),
            ControlFactory.sectionTitle("Appearance"),
            ControlFactory.popupRow("Style", stylePopup),
            ControlFactory.caption("Adaptive follows your system light or dark setting. Smoke is the heaviest, and hides the screen best."),
            ControlFactory.separator(),
            ControlFactory.sectionTitle("Color"),
            ControlFactory.popupRow("Source", tintSourcePopup),
            ControlFactory.popupRow("Custom color", tintWellRow()),
            ControlFactory.row("Strength", tintStrengthSlider, tintStrengthValueLabel),
            ControlFactory.caption("\"From wallpaper\" reads the colors of your desktop picture, and needs the original image file to still exist. \"System accent\" always works.")
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        view = ControlFactory.container(for: stack)
        refreshLabels()
    }

    /// The well keeps its natural size instead of stretching across the row.
    private func tintWellRow() -> NSStackView {
        tintWell.widthAnchor.constraint(equalToConstant: 64).isActive = true
        let row = NSStackView(views: [tintWell, NSView()])
        row.orientation = .horizontal
        row.distribution = .fill
        return row
    }

    private func refreshLabels() {
        intensityValueLabel.stringValue = ControlFactory.percent(settings.intensity)
        softnessValueLabel.stringValue = ControlFactory.percent(settings.softness)
        tintStrengthValueLabel.stringValue = ControlFactory.percent(settings.tintStrength)
        tintWell.isEnabled = settings.tintSource == .custom
        tintStrengthSlider.isEnabled = settings.tintSource != .none
    }

    @objc private func intensityChanged() {
        settings.intensity = CGFloat(intensitySlider.doubleValue)
        refreshLabels()
    }

    @objc private func softnessChanged() {
        settings.softness = CGFloat(softnessSlider.doubleValue)
        refreshLabels()
    }

    @objc private func styleChanged() {
        settings.blurStyle = BlurStyle(rawValue: stylePopup.indexOfSelectedItem) ?? .adaptive
    }

    @objc private func tintSourceChanged() {
        settings.tintSource = TintSource(rawValue: tintSourcePopup.indexOfSelectedItem) ?? .none
        refreshLabels()
    }

    @objc private func tintColorChanged() {
        settings.customTint = tintWell.color
    }

    @objc private func tintStrengthChanged() {
        settings.tintStrength = CGFloat(tintStrengthSlider.doubleValue)
        refreshLabels()
    }
}
