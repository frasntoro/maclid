import AppKit

protocol LidTabDelegate: AnyObject {
    func lidTab(didSetFollowsLid follows: Bool)
    func lidTab(didScrubTo progress: CGFloat)
    func lidTab(didRequestAnimationTo target: CGFloat)
}

/// "Coperchio" tab: when the effect triggers, plus the live readout and the
/// manual preview used to judge it without moving the lid.
final class LidTabViewController: NSViewController {

    private let settings: EffectSettings
    private let sensorAvailable: Bool
    weak var delegate: LidTabDelegate?

    private let angleLabel = NSTextField(labelWithString: "")
    private let followCheckbox: NSButton
    private var startAngleSlider: NSSlider!
    private var fullAngleSlider: NSSlider!
    private var progressSlider: NSSlider!
    private let startAngleValueLabel = NSTextField(labelWithString: "")
    private let fullAngleValueLabel = NSTextField(labelWithString: "")
    private let progressValueLabel = NSTextField(labelWithString: "")

    private var followsLid: Bool

    init(settings: EffectSettings, sensorAvailable: Bool, followsLid: Bool, delegate: LidTabDelegate? = nil) {
        self.settings = settings
        self.sensorAvailable = sensorAvailable
        self.followsLid = followsLid
        self.delegate = delegate
        followCheckbox = NSButton(checkboxWithTitle: "Follow the real lid", target: nil, action: nil)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        angleLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        angleLabel.stringValue = sensorAvailable
            ? "Lid angle: —"
            : "No angle sensor: a timed animation will be used instead"
        angleLabel.textColor = sensorAvailable ? .labelColor : .secondaryLabelColor

        followCheckbox.target = self
        followCheckbox.action = #selector(followChanged)
        followCheckbox.state = followsLid ? .on : .off
        followCheckbox.isEnabled = sensorAvailable

        startAngleSlider = ControlFactory.slider(min: 30, max: 135, value: settings.startAngle, target: self, action: #selector(startAngleChanged))
        fullAngleSlider = ControlFactory.slider(min: 0, max: 120, value: settings.fullAngle, target: self, action: #selector(fullAngleChanged))
        progressSlider = ControlFactory.slider(min: 0, max: 1, value: 0, target: self, action: #selector(progressChanged))

        let closeButton = NSButton(title: "Simulate closing", target: self, action: #selector(animateClosed))
        let openButton = NSButton(title: "Simulate opening", target: self, action: #selector(animateOpen))
        let buttonRow = NSStackView(views: [closeButton, openButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fillEqually

        let stack = NSStackView(views: [
            ControlFactory.sectionTitle("When it starts"),
            ControlFactory.row("Starts at", startAngleSlider, startAngleValueLabel),
            ControlFactory.row("Full at", fullAngleSlider, fullAngleValueLabel),
            ControlFactory.caption("Nothing happens above the start angle. Keep it below the angle you normally work at, or the screen will blur while you are using the Mac."),
            ControlFactory.separator(),
            ControlFactory.sectionTitle("Preview"),
            angleLabel,
            followCheckbox,
            ControlFactory.row("Closing", progressSlider, progressValueLabel),
            ControlFactory.caption("Uncheck to drag the closing by hand and judge the effect without moving the lid."),
            buttonRow
        ])
        stack.orientation = .vertical
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        view = ControlFactory.container(for: stack)
        refresh()
    }

    func updateMeasuredAngle(_ angle: Double) {
        guard sensorAvailable else { return }
        angleLabel.stringValue = "Lid angle: \(ControlFactory.degrees(angle))"
    }

    func updateProgressReadout(_ progress: CGFloat) {
        guard followsLid, isViewLoaded else { return }
        progressSlider.doubleValue = Double(progress)
        progressValueLabel.stringValue = ControlFactory.percent(progress)
    }

    func refresh() {
        guard isViewLoaded else { return }
        startAngleSlider.doubleValue = settings.startAngle
        fullAngleSlider.doubleValue = settings.fullAngle
        startAngleValueLabel.stringValue = ControlFactory.degrees(settings.startAngle)
        fullAngleValueLabel.stringValue = ControlFactory.degrees(settings.fullAngle)
        progressValueLabel.stringValue = ControlFactory.percent(CGFloat(progressSlider.doubleValue))
        progressSlider.isEnabled = !followsLid
    }

    @objc private func followChanged() {
        followsLid = followCheckbox.state == .on
        progressSlider.isEnabled = !followsLid
        delegate?.lidTab(didSetFollowsLid: followsLid)
    }

    @objc private func startAngleChanged() {
        settings.setStartAngle(startAngleSlider.doubleValue.rounded())
        refresh()
    }

    @objc private func fullAngleChanged() {
        settings.setFullAngle(fullAngleSlider.doubleValue.rounded())
        refresh()
    }

    @objc private func progressChanged() {
        let value = CGFloat(progressSlider.doubleValue)
        progressValueLabel.stringValue = ControlFactory.percent(value)
        delegate?.lidTab(didScrubTo: value)
    }

    @objc private func animateClosed() {
        setManualMode()
        delegate?.lidTab(didRequestAnimationTo: 1)
    }

    @objc private func animateOpen() {
        setManualMode()
        delegate?.lidTab(didRequestAnimationTo: 0)
    }

    private func setManualMode() {
        guard followsLid else { return }
        followCheckbox.state = .off
        followChanged()
    }
}
