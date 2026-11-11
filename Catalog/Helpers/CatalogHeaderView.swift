//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CatalogHeaderView: UITableViewHeaderFooterView {

    init() {
        super.init(reuseIdentifier: nil)
        let contentView = self.contentView
        let topBottomMargin: CGFloat = 16

        let image = UIImage(namedInCatalog: "nutrient-logo")?.withRenderingMode(.alwaysTemplate)
        let logo = UIImageView(image: image)
        logo.contentMode = .scaleAspectFit
        logo.tintColor = UIColor.psc_label
        contentView.addSubview(logo)
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.heightAnchor.constraint(equalToConstant: 28).isActive = true
        logo.widthAnchor.constraint(equalToConstant: 40).isActive = true
        logo.setContentCompressionResistancePriority(.required, for: .horizontal)
        let top = logo.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topBottomMargin)
        // Ensures the layout is not ambiguous while UITableView height calculation is still in flux.
        top.priority = UILayoutPriority(UILayoutPriority.required.rawValue - 1)
        top.isActive = true
        logo.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -topBottomMargin - 4).isActive = true
        logo.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor).isActive = true

        let version = UILabel()
        version.textColor = logo.tintColor
        version.attributedText = versionString
        version.numberOfLines = 2
        contentView.addSubview(version)
        version.translatesAutoresizingMaskIntoConstraints = false
        version.leadingAnchor.constraint(equalTo: logo.trailingAnchor, constant: 8).isActive = true
        version.centerYAnchor.constraint(equalTo: logo.centerYAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var versionString: NSAttributedString {
        let version = SDK.versionString
        let attributedVersionString = NSMutableAttributedString(string: version, attributes: [
            .font: UIFont.systemFont(ofSize: 14)
        ])
        let nutrientRange = (version as NSString).range(of: "Nutrient")
        if nutrientRange.location != NSNotFound {
            attributedVersionString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: nutrientRange)
        }
        return attributedVersionString
    }
}
