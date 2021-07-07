//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DisableBookmarkRenameExample: Example {

    override init() {
        super.init()

        title = "Disable Bookmark Rename"
        contentDescription = "Shows how to use a custom bookmark cell to disable bookmark renaming"
        category = .subclassing
        priority = 250
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let controller = PDFViewController(document: document) {
            // Use our PSPDFBookmarkCell subclass which has disabled bookmark editing.
            $0.overrideClass(BookmarkCell.self, with: DisableRenameBookmarkCell.self)
        }
        controller.navigationItem.setRightBarButtonItems([controller.outlineButtonItem, controller.bookmarkButtonItem], animated: false)

        return controller
    }
}

class DisableRenameBookmarkCell: BookmarkCell {

    /// Overriding this method and returning false disables the bookmark name editing when the cell is in edit mode.
    override func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
}
