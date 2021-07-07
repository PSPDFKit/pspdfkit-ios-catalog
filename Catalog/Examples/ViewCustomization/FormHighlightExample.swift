//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit
import PSPDFKitUI

class FormHighlightExample: Example {

    private weak var pdfController: PDFViewController?

    override init() {
        super.init()
        title = "Custom Form Highlight Color"
        contentDescription = "Shows how to toggle the form highlight color."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: AssetName(rawValue: "Form_example.pdf"))
        // Start by not highlighting forms.
        document.updateRenderOptions(for: .all) {
            $0.interactiveFormFillColor = .clear
        }

        let image = SDK.imageNamed("highlight.png")!
        let toggleButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleHighlight))

        let pdfController = PDFViewController(document: document)
        pdfController.navigationItem.rightBarButtonItems = [toggleButton]
        self.pdfController = pdfController
        return pdfController
    }

    // MARK: Actions

    @objc func toggleHighlight() {
        guard let pdfController = self.pdfController, let document = pdfController.document else {
            return
        }

        // Toggle between highlighted forms and clear forms.
        let currentColor = document.renderOptions(forType: .all).interactiveFormFillColor
        let highlightColor = UIColor.catalogTint.withAlphaComponent(0.2)

        document.updateRenderOptions(for: .page) { options in
            options.interactiveFormFillColor = currentColor == .clear ? highlightColor : .clear
        }

        pdfController.reloadData()
    }
}
