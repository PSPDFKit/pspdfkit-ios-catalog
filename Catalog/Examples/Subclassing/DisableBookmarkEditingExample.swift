//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DisableBookmarkEditingExample: Example {

    override init() {
        super.init()

        title = "Disable Bookmark Editing"
        contentDescription = "Shows how to disable bookmark editing using Document Features"
        category = .subclassing
        priority = 260
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        // Add the custom source to the document's features.
        let documentFeaturesSource = DisableBookmarkEditingDocumentFeaturesSource()
        document.features.add([documentFeaturesSource])

        let controller = PDFViewController(document: document)
        controller.navigationItem.setRightBarButtonItems([controller.outlineButtonItem], animated: false)
        return controller
    }
}

private class DisableBookmarkEditingDocumentFeaturesSource: NSObject, PDFDocumentFeaturesSource {
    weak var features: PDFDocumentFeatures?

    // Return false to disable bookmark editing.
    var canEditBookmarks: Bool {
        false
    }
}
