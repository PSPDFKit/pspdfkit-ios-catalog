//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class DisableScrollBouncingExample: Example, PDFDocumentViewControllerDelegate {

    override init() {
        super.init()

        title = "Disable Scroll View Bouncing"
        contentDescription = "Disable bouncing for the document scroll view zoom and zoom view"
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: document)
        controller.documentViewController?.delegate = self
        return controller
    }

    // MARK: PDFViewControllerDelegate

    // Disables bouncing on the scroll view, even when fully zoomed out.
    // Noticeable when scrolling to the left on the first page, or when scrolling to the right on the last page.
    func documentViewController(_ documentViewController: PDFDocumentViewController, configureScrollView scrollView: UIScrollView) {
        scrollView.bounces = false
    }

    // Disables bouncing when scrolling while zoomed in.
    func documentViewController(_ documentViewController: PDFDocumentViewController, configureZoom zoomView: UIScrollView, forSpreadAt spreadIndex: Int) {
        zoomView.bounces = false
    }
}
