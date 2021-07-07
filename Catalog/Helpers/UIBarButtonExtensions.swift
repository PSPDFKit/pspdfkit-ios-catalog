//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

private var UIBarButtonActionBlockKey: Character = "0"

extension UIBarButtonItem {

    typealias UIBarButtonItemAction = (_ sender: AnyObject?) -> Void

    /// Creates a new `UIBarButtonItem` that executes the given action block.
    @objc(psc_initWithTitle:style:action:)
    convenience init(title: String, style: UIBarButtonItem.Style, action: @escaping UIBarButtonItemAction) {
        self.init(title: title, style: style, target: nil, action: #selector(psc_executeAction(_:)))
        target = self

        self.actionBlock = action
    }

    private var actionBlock: UIBarButtonItemAction? {
        get { objc_getAssociatedObject(self, &UIBarButtonActionBlockKey) as? UIBarButtonItemAction }
        set { objc_setAssociatedObject(self, &UIBarButtonActionBlockKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }

    @objc private func psc_executeAction(_ sender: AnyObject?) {
        actionBlock?(sender)
    }
}
