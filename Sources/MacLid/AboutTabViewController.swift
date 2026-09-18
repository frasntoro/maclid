import AppKit
import IconArt

/// "Info" tab: what this is, which version, and who made it.
final class AboutTabViewController: NSViewController {

    private let sensorAvailable: Bool

    init(sensorAvailable: Bool) {
        self.sensorAvailable = sensorAvailable
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let iconSide: CGFloat = 96
        let iconView = NSImageView()
        // Rendered at 2x so it stays crisp on Retina.
        iconView.image = NSImage(
            cgImage: IconArtwork.image(size: Int(iconSide * 2)),
            size: NSSize(width: iconSide, height: iconSide)
        )
        iconView.heightAnchor.constraint(equalToConstant: iconSide).isActive = true

        let nameLabel = NSTextField(labelWithString: AppInfo.name)
        nameLabel.font = .systemFont(ofSize: 26, weight: .semibold)

        let taglineLabel = NSTextField(labelWithString: AppInfo.tagline)
        taglineLabel.textColor = .secondaryLabelColor

        let versionLabel = NSTextField(labelWithString: "Version \(AppInfo.version) (\(AppInfo.build))")
        versionLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center

        let authorLabel = NSTextField(labelWithString: "by \(AppInfo.author) — \(AppInfo.handle)")
        authorLabel.alignment = .center

        let sensorLabel = ControlFactory.caption(
            sensorAvailable
                ? "On this Mac the blur follows the real lid angle, read from the system sensor."
                : "This Mac does not expose the lid angle sensor, so the blur runs as a timed animation on sleep and wake."
        )
        sensorLabel.alignment = .center

        let stack = NSStackView(views: [
            iconView,
            nameLabel,
            taglineLabel,
            versionLabel,
            authorLabel,
            sensorLabel
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.setCustomSpacing(18, after: taglineLabel)
        stack.setCustomSpacing(2, after: versionLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 440),
            stack.widthAnchor.constraint(equalToConstant: 360),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -28)
        ])
        view = container
    }
}
