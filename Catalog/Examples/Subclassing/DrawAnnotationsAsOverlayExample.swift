//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// This is an example showing how to modify all annotations to render as overlays.
/// Note that this is a corner case and isn't as well tested.
/// This helps in case you want to add custom subviews but still have drawings on top of everything.
class DrawAnnotationsAsOverlayExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Draw all annotations as overlay"
        contentDescription = "Allows annotations to render on top of custom subviews of the page view."
        category = .subclassing
        priority = 150
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)

        // Register our custom annotation provider as subclass before the view controller is initialized.
        document.overrideClass(PDFFileAnnotationProvider.self, with: OverlayFileAnnotationProvider.self)

        let pdfViewController = PDFViewController(document: document)
        pdfViewController.navigationItem.setRightBarButtonItems([pdfViewController.thumbnailsButtonItem, pdfViewController.annotationButtonItem], for: .document, animated: false)
        pdfViewController.delegate = self

        return pdfViewController
    }

    // MARK: PDFViewControllerDelegate

    func pdfViewController(_ pdfController: PDFViewController, didConfigurePageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        // Add a custom view on every page to demonstrate that the annotations will render ABOVE that view.
        let customView = CustomView(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        customView.backgroundColor = UIColor(red: 1, green: 0.846, blue: 0.088, alpha: 0.9)
        customView.layer.cornerRadius = 10
        customView.layer.borderColor = UIColor(red: 1, green: 0.846, blue: 0.088, alpha: 1).cgColor
        customView.layer.borderWidth = 2
        customView.alpha = 0.5

        pageView.insertSubview(customView, belowSubview: pageView.annotationContainerView)
    }

    func pdfViewController(_ pdfController: PDFViewController, didCleanupPageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        pageView.subviews.first { $0 is CustomView }!.removeFromSuperview()
    }
}

private class CustomView: UIView {
}

private class OverlayFileAnnotationProvider: PDFFileAnnotationProvider {

    override func annotationsForPage(at pageIndex: PageIndex) -> [Annotation]? {
        let annotations = super.annotationsForPage(at: pageIndex) ?? []

        // Make annotations overlay annotations so they will be rendered in their own views instead of within the page image.
        // Making highlights as overlay really really doesn't look good. (Since they are multiplied into the page content this is not possible with regular UIView composition, so you would need to completely overlap the text unless you make them semi-transparent.)
        for annotation in annotations where annotation is TextMarkupAnnotation == false {
            annotation.isOverlay = true
        }

        return annotations
    }

    override func add(_ annotations: [Annotation], options: [AnnotationManager.ChangeBehaviorKey: Any]? = nil) -> [Annotation]? {
        // Set annotations to render as overlays right after they are inserted.
        for annotation in annotations where annotation is TextMarkupAnnotation == false {
            annotation.isOverlay = true
        }

        return super.add(annotations, options: options)
    }
}
