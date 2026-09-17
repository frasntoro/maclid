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

        let authorLabel = NSTextField(labelWithString: "by \(AppInfo.author) — \(AppInfo.handle)")

        let sensorLabel = ControlFactory.caption(
            sensorAvailable
                ? "On this Mac the blur follows the real lid angle, read from the system sensor."
                : "This Mac does not expose the lid angle sensor, so the blur runs as a timed animation on sleep and wake."
        )

        let header = NSStackView(views: [iconView, nameLabel, taglineLabel])
        header.orientation = .vertical
        header.alignment = .centerX
        header.spacing = 6

        let stack = NSStackView(views: [
            header,
            ControlFactory.separator(),
            versionLabel,
            authorLabel,
            sensorLabel
        ])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)

        view = ControlFactory.container(for: stack)
    }
}
