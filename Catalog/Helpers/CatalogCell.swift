//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CatalogCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(with content: Content, showLanguageBadge: Bool) {
        setup(with: content)
        textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        let language: ExampleLanguage? = showLanguageBadge ? (content.example?.isSwift ?? true ? .swift : .objectiveC) : nil
        accessoryView = accessoryView(language: language)
    }

    func setupSectionHeader(with content: Content, collapsed: Bool) {
        setup(with: content)
        if #available(iOS 14.0, *) {
            let imageName = Example.systemImageForExampleCategory(content.category!)
            imageView?.image = UIImage(systemName: imageName)
        }
        textLabel?.font = .preferredFont(forTextStyle: .headline)
        accessoryView = accessoryViewForSectionHeader(collapsed: collapsed)
    }

    private func setup(with content: Content) {
        textLabel?.attributedText = content.title
        textLabel?.numberOfLines = 0
        detailTextLabel?.text = content.contentDescription
        detailTextLabel?.textColor = .psc_secondaryLabel
        detailTextLabel?.numberOfLines = 0
        imageView?.image = content.image
    }

    private func accessoryViewForSectionHeader(collapsed: Bool) -> UIView {
        let arrow = arrowView(collapsed: collapsed)
        return accessoryView(with: [arrow])
    }

    private func accessoryView(language: ExampleLanguage?) -> UIView {
        let arrow = arrowView()
        if let language = language {
            let badge = badgeView(language: language)
            return accessoryView(with: [badge, arrow])
        } else {
            return accessoryView(with: [arrow])
        }
    }

    private func accessoryView(with views: [UIView]) -> UIView {
        let accessoryView = UIStackView(arrangedSubviews: views)
        accessoryView.tintColor = UIColor.psc_accessoryView
        accessoryView.spacing = 8
        accessoryView.axis = .horizontal
        let size = accessoryView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        accessoryView.bounds = CGRect(origin: .zero, size: size)
        return accessoryView
    }

    private func badgeView(language: ExampleLanguage) -> UIView {
        let badgeView = UIImageView()
        badgeView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        badgeView.image = UIImage(named: language.imageName)
        return badgeView
    }

    private func arrowView(collapsed: Bool? = nil) -> UIView {
        let arrowImage = SDK.imageNamed("arrow-right-landscape")!.withRenderingMode(.alwaysTemplate).imageFlippedForRightToLeftLayoutDirection()
        let arrowView = UIImageView(image: arrowImage)
        arrowView.contentMode = .center
        if let collapsed = collapsed {
            if collapsed {
                arrowView.transform = CGAffineTransform(rotationAngle: .pi / 2)
            } else {
                arrowView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
            }
        }
        return arrowView
    }
}

extension ExampleLanguage {
    var imageName: String {
        switch self {
        case .swift:
            return "swift-badge"
        case .objectiveC:
            return "objc-badge"
        @unknown default:
            fatalError()
        }
    }
}
