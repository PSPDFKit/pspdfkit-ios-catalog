//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class SearchHighlightColorExample: Example {

    override init() {
        super.init()
            title = "Custom Inline Search Highlight Color"
            contentDescription = "Changes the search highlight color for inline search to blue via UIAppearance."
            category = .viewCustomization
            priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)

        // We use a custom subclass of the PDFViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
        SearchHighlightView.appearance(whenContainedInInstancesOf: [CustomColoredSearchHighlightPDFViewController.self]).selectionBackgroundColor = UIColor.blue.withAlphaComponent(0.5)

        let pdfController = CustomColoredSearchHighlightPDFViewController(document: document) {
            $0.searchMode = .inline
        }

        // Automatically start search.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            pdfController.search(for: "Nutrient", options: nil, sender: nil, animated: true)
        }

        return pdfController
    }
}

// Custom empty subclass of the PDFViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
private class CustomColoredSearchHighlightPDFViewController: PDFViewController {
}

class ModalSearchHighlightColorExample: Example {

    override init() {
        super.init()
        title = "Custom Modal Search Highlight Color"
        contentDescription = "Changes the search highlight color to red in SearchViewController."
        category = .viewCustomization
        priority = 49
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)

        let pdfController = PDFViewController(document: document) {
            $0.overrideClass(SearchViewController.self, with: CustomHighlightSearchViewController.self)
        }

        // Automatically start search.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            pdfController.search(for: "Nutrient", options: nil, sender: nil, animated: true)
        }

        return pdfController
    }
}

private class CustomHighlightSearchViewController: SearchViewController {

    override init(document: Document?) {
        super.init(document: document)
        highlightColor = .red
    }
}
