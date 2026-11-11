//
//  Copyright © 2018-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CalculatorExample: Example {
    override init() {
        super.init()

        title = "Calculator in a PDF with embedded JavaScript"
        contentDescription = "Example showing JavaScript support in Nutrient."
        category = .miscellaneous
        priority = 1
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Calculator.pdf")

        // Create a custom configuration that hides the UI elements that are not relevant for this example.
        let configuration = PDFConfiguration {
            $0.thumbnailBarMode = .none
            $0.isPageLabelEnabled = false
            $0.shouldShowUserInterfaceOnViewWillAppear = false
        }

        let pdfController = PDFViewController(document: document, configuration: configuration)
        // Hide the default PDFViewController navigation items.
        pdfController.navigationItem.rightBarButtonItems = []

        return pdfController
    }

}
