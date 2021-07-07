//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

class InstantExampleDocumentLinkCell: UITableViewCell {
    let textField = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        textField.placeholder = "Enter Document Link"

        textField.clearButtonMode = .always
        textField.keyboardType = .URL
        textField.textContentType = .URL
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done

        textField.font = UIFont.preferredFont(forTextStyle: .body)

        contentView.addSubview(textField)
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let availableWidth = size.width - layoutMargins.left - layoutMargins.right
        let height = layoutMargins.top + textField.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude)).height + layoutMargins.bottom
        return CGSize(width: size.width, height: max(height, 44))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        textField.frame = convert(bounds.inset(by: layoutMargins), to: contentView)
    }
}
