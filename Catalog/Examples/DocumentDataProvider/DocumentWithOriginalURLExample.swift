//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DocumentWithOriginalURLExample: Example {
    override init() {
        super.init()
        title = "Document with originalURL set"
        contentDescription = "Additional options for Open In"
        category = .documentDataProvider
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        // Define original file to get additional Open In options.
        document.originalFile = File(name: "My custom file.pdf", url: AssetLoader.document(for: .about).fileURL, data: nil)

        let controller = PDFViewController(document: document) {
            $0.pageMode = .single
        }

        return controller
    }
}
