//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

class MultimediaExample: Example {
    override init() {
        super.init()
            title = "Multimedia PDF example"
            contentDescription = "Load PDF with various multimedia additions and an embedded video."
            category = .multimedia
            priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: "multimedia.pdf")
        let pdfController = PDFViewController(document: document)
        pdfController.navigationItem.setRightBarButtonItems([pdfController.thumbnailsButtonItem, pdfController.openInButtonItem], for: .document, animated: false)
        return pdfController
    }
}
