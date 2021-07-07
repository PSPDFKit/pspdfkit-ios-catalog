//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class SearchWithoutControllerExample: Example {

    override init() {
        super.init()

        title = "Headless Search Example"
        contentDescription = "Search programmatically without displaying search controller."
        category = .subclassing
        priority = 140
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = HeadlessSearchPDFViewController(document: document)
        pdfController.highlightedSearchText = "PSPDFKit"
        return pdfController
    }
}

private class HeadlessSearchPDFViewController: PDFViewController, PDFViewControllerDelegate {

    var highlightedSearchText: String? {
        didSet {
            if oldValue != highlightedSearchText {
                updateTextHighlight()
            }
        }
    }

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration.configurationUpdated {
            // Register the override to use a custom search highlight view subclass.
            $0.overrideClass(SearchHighlightView.self, with: NonAnimatingSearchHighlightView.self)
        })

        // We are using the delegate to be informed about page loads.
        delegate = self
    }

    // MARK: - PSPDFViewControllerDelegate

    func pdfViewController(_ pdfController: PDFViewController, didConfigurePageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        // Restart search if we have a new pageView loaded.
        updateTextHighlight()
    }

    // MARK: - Private

    private func updateTextHighlight() {
        search(for: highlightedSearchText, options: [PresentationOption.searchHeadless: NSNumber(value: true)], sender: nil, animated: false)
    }
}

private class NonAnimatingSearchHighlightView: SearchHighlightView {

    override func popupAnimation() {
        // No Operation: We do not want to perform an animation.
    }
}
