//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class SearchHighlightColorExample: Example {

    override init() {
        super.init()
            title = "Custom Search Highlight Color"
            contentDescription = "Changes the search highlight color to blue via UIAppearance."
            category = .viewCustomization
            priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)

        // We use a custom subclass of the PDFViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
        SearchHighlightView.appearance(whenContainedInInstancesOf: [CustomColoredSearchHighlightPDFViewController.self]).selectionBackgroundColor = UIColor.blue.withAlphaComponent(0.5)

        let pdfController = CustomColoredSearchHighlightPDFViewController(document: document) {
            $0.searchMode = .inline
        }

        // Automatically start search.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            pdfController.search(for: "PSPDFKit", options: nil, sender: nil, animated: true)
        }

        return pdfController
    }
}

// Custom empty subclass of the PDFViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
private class CustomColoredSearchHighlightPDFViewController: PDFViewController {
}
