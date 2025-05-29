//
//  Copyright © 2016-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class DocumentWithOriginalFileExample: Example {
    override init() {
        super.init()
        title = "Document with originalFile set"
        contentDescription = "Additional options for Open In"
        category = .documentDataProvider
        priority = 5
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)
        // Define original file to get additional Open In options.
        document.originalFile = File(name: "My custom file.pdf", url: AssetLoader.document(for: .about).fileURL, data: nil)

        let controller = PDFViewController(document: document) {
            $0.pageMode = .single
        }

        return controller
    }
}
