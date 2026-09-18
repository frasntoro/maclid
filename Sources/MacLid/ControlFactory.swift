import AppKit

enum ControlFactory {

    static func slider(min: Double, max: Double, value: Double, target: AnyObject, action: Selector) -> NSSlider {
        let slider = NSSlider()
        slider.minValue = min
        slider.maxValue = max
        slider.doubleValue = value
        slider.isContinuous = true
        slider.target = target
        slider.action = action
        return slider
    }

    static func row(
        _ title: String,
        _ slider: NSSlider,
        _ valueLabel: NSTextField,
        titleWidth: CGFloat = 92,
        valueWidth: CGFloat = 52
    ) -> NSStackView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.alignment = .right
        titleLabel.widthAnchor.constraint(equalToConstant: titleWidth).isActive = true

        valueLabel.alignment = .right
        valueLabel.widthAnchor.constraint(equalToConstant: valueWidth).isActive = true

        let row = NSStackView(views: [titleLabel, slider, valueLabel])
        row.orientation = .horizontal
        row.spacing = 10
        return row
    }

    static func popupRow(_ title: String, _ control: NSView, titleWidth: CGFloat = 92) -> NSStackView {
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.alignment = .right
        titleLabel.widthAnchor.constraint(equalToConstant: titleWidth).isActive = true

        let row = NSStackView(views: [titleLabel, control])
        row.orientation = .horizontal
        row.spacing = 10
        return row
    }

    /// Title and value on one line, the control full width underneath: the
    /// layout Control Center uses, which suits a narrow panel.
    static func stackedRow(_ title: String, _ control: NSView, _ valueLabel: NSTextField) -> NSStackView {
        let titleLabel = NSTextField(labelWithString: title)
        valueLabel.alignment = .right
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        let header = NSStackView(views: [titleLabel, NSView(), valueLabel])
        header.orientation = .horizontal
        header.distribution = .fill

        let row = NSStackView(views: [header, control])
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 6
        for view in row.arrangedSubviews {
            view.widthAnchor.constraint(equalTo: row.widthAnchor).isActive = true
        }
        return row
    }

    /// Keeps a control at its natural size, left-aligned, in a stack that
    /// stretches its rows across the full width.
    static func leading(_ view: NSView) -> NSStackView {
        let row = NSStackView(views: [view, NSView()])
        row.orientation = .horizontal
        row.distribution = .fill
        return row
    }

    /// Lines a view up with the controls of `row` and `popupRow`, past their
    /// title column, so a caption sits under the control it explains.
    static func indented(_ view: NSView, titleWidth: CGFloat = 92) -> NSStackView {
        let row = NSStackView(views: [view])
        row.orientation = .horizontal
        row.edgeInsets = NSEdgeInsets(top: 0, left: titleWidth + 10, bottom: 0, right: 0)
        return row
    }

    static func caption(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        return label
    }

    static func sectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        return label
    }

    static func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    /// Wraps a stack in a fixed-width container so the window can size itself
    /// from the content instead of guessing.
    static func container(for stack: NSStackView, width: CGFloat = 440) -> NSView {
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: width),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Rows span the full content width, so labels wrap and sliders stretch.
        let contentWidth = -(stack.edgeInsets.left + stack.edgeInsets.right)
        for subview in stack.arrangedSubviews {
            subview.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: contentWidth).isActive = true
        }
        return container
    }

    static func percent(_ value: CGFloat) -> String {
        "\(Int(round(value * 100)))%"
    }

    static func degrees(_ value: Double) -> String {
        "\(Int(round(value)))°"
    }

}
