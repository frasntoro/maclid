import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let settings = EffectSettings()

    private var statusBarController: StatusBarController!
    private var overlayController: OverlayWindowController!
    private var settingsWindowController: SettingsWindowController?
    private var lidSensor: LidAngleSensor?
    private var followsLid = true
    private var isScreenLocked = false

    private let fadeDuration: TimeInterval = 0.8

    /// The sensor reports whole degrees, so each step would land as a visible jump.
    /// Interpolating over slightly more than one sensor tick turns them into a glide.
    private let trackingDuration: TimeInterval = 0.12

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlayController = OverlayWindowController()
        statusBarController = StatusBarController(
            settings: settings,
            onOpenSettings: { [weak self] in self?.openSettingsWindow() },
            onQuit: { NSApp.terminate(nil) },
            onPanelVisibilityChange: { [weak self] isVisible in
                self?.overlayController.isSuppressed = isVisible
            }
        )

        settings.onChange = { [weak self] in self?.applySettings() }
        applySettings()

        lidSensor = LidAngleSensor()
        registerSleepWakeObservers()
        updateSensorMonitoring()
    }

    /// Nothing worth watching while the effect is off.
    private func updateSensorMonitoring() {
        guard let sensor = lidSensor else { return }

        if settings.isEnabled, !isScreenLocked {
            if !sensor.isRunning {
                sensor.startMonitoring { [weak self] angle in
                    self?.handleLidAngle(angle)
                }
            }
        } else {
            sensor.stop()
        }
    }

    private func applySettings() {
        overlayController.intensity = settings.intensity
        overlayController.softness = settings.softness
        overlayController.motion = settings.motion
        overlayController.tintStrength = settings.tintStrength
        overlayController.tint = resolveTint()
        settingsWindowController?.refresh()
        updateSensorMonitoring()

        guard settings.isEnabled else {
            overlayController.setProgress(0, duration: fadeDuration)
            return
        }

        if followsLid, let angle = lidSensor?.readAngle() {
            handleLidAngle(angle)
        }
    }

    private func resolveTint() -> GradientTint? {
        switch settings.tintSource {
        case .glass:
            return nil
        case .wallpaper:
            // nil when the desktop picture file is gone: no tint rather than a guess.
            return NSScreen.main.flatMap(WallpaperTint.dominantColor(for:)).map(GradientTint.solid)
        case .color:
            return .solid(settings.customTint)
        case .gradient:
            return settings.gradient
        }
    }

    private func handleLidAngle(_ angle: Double) {
        settingsWindowController?.updateMeasuredAngle(angle)
        guard followsLid, settings.isEnabled else { return }

        let span = max(settings.startAngle - settings.fullAngle, 1)
        let progress = CGFloat(min(max((settings.startAngle - angle) / span, 0), 1))
        overlayController.setProgress(progress, duration: trackingDuration, timing: .linear)
        settingsWindowController?.updateProgressReadout(progress)
    }

    private func registerSleepWakeObservers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(handleWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(handleDidWake), name: NSWorkspace.didWakeNotification, object: nil)

        // The lock screen is drawn above every app window, so the effect can't be
        // seen while locked — no reason to keep reading the sensor for it.
        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(self, selector: #selector(handleScreenLocked), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        distributed.addObserver(self, selector: #selector(handleScreenUnlocked), name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    @objc private func handleScreenLocked() {
        isScreenLocked = true
        overlayController.setProgress(0)
        updateSensorMonitoring()
    }

    @objc private func handleScreenUnlocked() {
        isScreenLocked = false
        updateSensorMonitoring()
    }

    /// Fallback for Macs without a lid angle sensor: a timed fade on sleep.
    @objc private func handleWillSleep() {
        guard settings.isEnabled, lidSensor == nil else { return }
        overlayController.setProgress(1, duration: fadeDuration)
    }

    @objc private func handleDidWake() {
        guard settings.isEnabled, lidSensor == nil else { return }
        overlayController.setProgress(0, duration: fadeDuration)
    }

    private func openSettingsWindow() {
        statusBarController.closePanel()

        if let controller = settingsWindowController {
            controller.show()
            return
        }

        let controller = SettingsWindowController(
            settings: settings,
            sensorAvailable: lidSensor != nil,
            followsLid: followsLid,
            delegate: self
        )
        settingsWindowController = controller
        controller.show()
    }
}

extension AppDelegate: SettingsWindowDelegate {

    func settingsWindow(didSetFollowsLid follows: Bool) {
        followsLid = follows
        // Hand control back to the lid: nothing to keep the window raised for.
        settingsWindowController?.setPreviewing(!follows)
        if follows, let angle = lidSensor?.readAngle() {
            handleLidAngle(angle)
        }
    }

    func settingsWindow(didScrubTo progress: CGFloat) {
        settingsWindowController?.setPreviewing(true)
        overlayController.setProgress(progress)
    }

    func settingsWindow(didRequestAnimationTo target: CGFloat) {
        settingsWindowController?.setPreviewing(true)
        overlayController.setProgress(target, duration: fadeDuration)
    }

    func settingsWindowWillClose() {
        settingsWindowController = nil
        followsLid = true

        if let angle = lidSensor?.readAngle() {
            handleLidAngle(angle)
        } else {
            overlayController.setProgress(0, duration: fadeDuration)
        }
    }
}
