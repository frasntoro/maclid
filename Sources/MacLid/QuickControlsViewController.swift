import AppKit

/// Content of the menu bar popover: the handful of controls worth reaching in
/// two seconds. Everything else lives in the settings window.
final class QuickControlsViewController: NSViewController {

    private let settings: EffectSettings
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void

    private let enabledSwitch = NSSwitch()
    private var intensitySlider: NSSlider!
    private var attackSlider: NSSlider!
    private let intensityValueLabel = NSTextField(labelWithString: "")
    private let attackValueLabel = NSTextField(labelWithString: "")

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
        attackSlider = ControlFactory.slider(min: 30, max: 135, value: settings.startAngle, target: self, action: #selector(attackChanged))

        let attackCaptions = NSStackView(views: [
            ControlFactory.caption("Near closed"),
            NSView(),
            ControlFactory.caption("Right away")
        ])
        attackCaptions.orientation = .horizontal
        attackCaptions.distribution = .fill

        let settingsButton = NSButton(title: "Settings…", target: self, action: #selector(openSettings))
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quit))
        let buttonRow = NSStackView(views: [settingsButton, quitButton])
        buttonRow.orientation = .horizontal
        buttonRow.distribution = .fillEqually

        let stack = NSStackView(views: [
            headerRow,
            ControlFactory.row("Intensity", intensitySlider, intensityValueLabel, titleWidth: 70, valueWidth: 44),
            ControlFactory.row("Start", attackSlider, attackValueLabel, titleWidth: 70, valueWidth: 44),
            attackCaptions,
            buttonRow
        ])
        stack.orientation = .vertical
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 300),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
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
        attackSlider.doubleValue = settings.startAngle
        intensityValueLabel.stringValue = ControlFactory.percent(settings.intensity)
        attackValueLabel.stringValue = ControlFactory.degrees(settings.startAngle)
    }

    @objc private func enabledChanged() {
        settings.isEnabled = enabledSwitch.state == .on
    }

    @objc private func intensityChanged() {
        settings.intensity = CGFloat(intensitySlider.doubleValue)
        intensityValueLabel.stringValue = ControlFactory.percent(settings.intensity)
    }

    @objc private func attackChanged() {
        settings.startAngle = attackSlider.doubleValue
        attackValueLabel.stringValue = ControlFactory.degrees(settings.startAngle)
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quit() {
        onQuit()
    }
}
