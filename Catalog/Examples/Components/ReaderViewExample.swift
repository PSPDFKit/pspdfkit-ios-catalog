//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

class ReaderViewExample: Example {

    override init() {
        super.init()

        self.title = "Reader View"
        self.contentDescription = "Shows Reader View, which reformats document text for easy reading."
        self.type = "com.pspdfkit.catalog.default"
        self.category = .componentsExamples
        self.priority = 2
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {

        let document = AssetLoader.document(for: .cosmicContextForLife)
        let controller = PDFViewController(document: document)

        controller.navigationItem.rightBarButtonItems = [controller.thumbnailsButtonItem, controller.readerViewButtonItem]

        return controller
    }
}
