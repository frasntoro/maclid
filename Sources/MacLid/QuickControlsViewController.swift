import AppKit

/// Content of the menu bar popover: the handful of controls worth reaching in
/// two seconds. Everything else lives in the settings window.
final class QuickControlsViewController: NSViewController {

    private let settings: EffectSettings
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void

    private let enabledSwitch = NSSwitch()
    private var intensitySlider: NSSlider!
    private var startSlider: NSSlider!
    private var fullSlider: NSSlider!
    private let intensityValueLabel = NSTextField(labelWithString: "")
    private let startValueLabel = NSTextField(labelWithString: "")
    private let fullValueLabel = NSTextField(labelWithString: "")

    init(settings: EffectSettings, onOpenSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.settings = settings
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let titleLabel = NSTextField(labelWithString: "MacLid")
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        enabledSwitch.target = self
        enabledSwitch.action = #selector(enabledChanged)

        let headerRow = NSStackView(views: [titleLabel, NSView(), enabledSwitch])
        headerRow.orientation = .horizontal
        headerRow.distribution = .fill

        intensitySlider = ControlFactory.slider(min: 0.2, max: 1, value: Double(settings.intensity), target: self, action: #selector(intensityChanged))
        startSlider = ControlFactory.slider(min: 30, max: 135, value: settings.startAngle, target: self, action: #selector(startChanged))
        fullSlider = ControlFactory.slider(min: 0, max: 120, value: settings.fullAngle, target: self, action: #selector(fullChanged))

        let settingsButton = NSButton(title: "Settings", target: self, action: #selector(openSettings))
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quit))
        let buttonRow = NSStackView(views: [settingsButton, quitButton])
        buttonRow.orientation = .horizontal
        buttonRow.distribution = .fillEqually

        let fullRow = ControlFactory.stackedRow("Full at", fullSlider, fullValueLabel)

        let stack = NSStackView(views: [
            headerRow,
            ControlFactory.stackedRow("Intensity", intensitySlider, intensityValueLabel),
            ControlFactory.stackedRow("Starts at", startSlider, startValueLabel),
            fullRow,
            buttonRow
        ])
        stack.orientation = .vertical
        stack.spacing = 14
        stack.setCustomSpacing(18, after: fullRow)
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        view = ControlFactory.container(for: stack, width: 300)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
        preferredContentSize = view.fittingSize
    }

    /// Pulls current values back in, since the settings window edits the same object.
    /// Before the first presentation the view isn't loaded yet; `viewDidLoad` refreshes.
    func refresh() {
        guard isViewLoaded else { return }

        enabledSwitch.state = settings.isEnabled ? .on : .off
        intensitySlider.doubleValue = Double(settings.intensity)
        startSlider.doubleValue = settings.startAngle
        fullSlider.doubleValue = settings.fullAngle
        intensityValueLabel.stringValue = ControlFactory.percent(settings.intensity)
        startValueLabel.stringValue = ControlFactory.degrees(settings.startAngle)
        fullValueLabel.stringValue = ControlFactory.degrees(settings.fullAngle)
    }

    @objc private func enabledChanged() {
        settings.isEnabled = enabledSwitch.state == .on
    }

    @objc private func intensityChanged() {
        settings.intensity = CGFloat(intensitySlider.doubleValue)
        intensityValueLabel.stringValue = ControlFactory.percent(settings.intensity)
    }

    @objc private func startChanged() {
        settings.setStartAngle(startSlider.doubleValue.rounded())
        refresh()
    }

    @objc private func fullChanged() {
        settings.setFullAngle(fullSlider.doubleValue.rounded())
        refresh()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quit() {
        onQuit()
    }
}
