import AppKit

/// "General" tab: the things set once and then forgotten, kept out of the
/// menu bar panel so it only holds what you reach for daily.
final class GeneralTabViewController: NSViewController {

    private let loginItemCheckbox = NSButton(checkboxWithTitle: "Launch MacLid at login", target: nil, action: nil)

    override func loadView() {
        loginItemCheckbox.target = self
        loginItemCheckbox.action = #selector(loginItemChanged)
        loginItemCheckbox.isEnabled = LoginItem.isAvailable

        // A link, not a background check: the app never reaches the network on
        // its own, and that is worth keeping true.
        let updatesButton = NSButton(title: "Check for updates", target: self, action: #selector(openReleases))
        updatesButton.bezelStyle = .rounded

        let versionLabel = NSTextField(labelWithString: "Version \(AppInfo.version)")
        versionLabel.textColor = .secondaryLabelColor

        let updatesControls = NSStackView(views: [updatesButton, versionLabel, NSView()])
        updatesControls.orientation = .horizontal
        updatesControls.spacing = 12

        let stack = NSStackView(views: [
            ControlFactory.popupRow("Startup", loginItemCheckbox),
            ControlFactory.indented(ControlFactory.caption(
                LoginItem.isAvailable
                    ? "MacLid starts quietly in the menu bar, with the settings you left."
                    : "Available once MacLid is running from the app in your Applications folder."
            )),
            ControlFactory.separator(),
            ControlFactory.popupRow("Updates", updatesControls),
            ControlFactory.indented(ControlFactory.caption(
                "MacLid never goes online by itself. The button opens the releases page, where new versions are published."
            ))
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(4, after: stack.arrangedSubviews[0])
        stack.setCustomSpacing(4, after: stack.arrangedSubviews[3])

        view = ControlFactory.container(for: stack)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // Can also change from System Settings › General › Login Items.
        loginItemCheckbox.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func loginItemChanged() {
        let wanted = loginItemCheckbox.state == .on
        if !LoginItem.setEnabled(wanted) {
            // Registration refused: don't leave the checkbox claiming otherwise.
            loginItemCheckbox.state = wanted ? .off : .on
        }
    }

    @objc private func openReleases() {
        NSWorkspace.shared.open(AppInfo.releasesURL)
    }
}
