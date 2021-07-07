//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// Example that adds a custom overlaying view to the `PDFPageView` when a user selects an annotation.
class ShowAuthorNameOnAnnotationSelectionExample: Example {

    override init() {
        super.init()

        title = "Show Author Name On Annotation Selection"
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        let controller = CustomOverlayingViewViewController(document: document)

        // Add annotation interaction hooks to display author name.
        controller.addAnnotationInteractionActions()

        // Show a page with annotations.
        controller.pageIndex = 15

        return controller
    }
}

/// `PDFViewController` subclass that can add actions to be executed on a user interaction with annotations.
private class CustomOverlayingViewViewController: PDFViewController {

    /// Currently visible overlaying view.
    var displayingCustomOverlayView: CustomOverlayLabelView?

    /// Adds the actions to be executed whenever the user selects or de-selects an annotation.
    func addAnnotationInteractionActions() {
        // `selectAnnotation.addActivationCallback` code block is called whenever a user selects an annotation.
        self.interactions.selectAnnotation.addActivationCallback { context, _, _  in
            // Use the provided context to get the page and annotation about to be selected.
            let selectedAnnotation = context.annotation
            let authorName = selectedAnnotation.user ?? "Unknown Author"
            let pageView = context.pageView

            // `boundingBox` is in the page coordinates that is in the PDF coordinate space which means
            // origin is at the bottom left.
            // For more info: https://pspdfkit.com/guides/ios/faq/coordinate-spaces/
            let selectedAnnotationBoundingBox = selectedAnnotation.boundingBox
            // We anchor the custom overlay view at the centre of the annotation.
            let viewSize: CGFloat = 40
            let authorViewRect = CGRect(x: selectedAnnotationBoundingBox.midX - (viewSize / 2), y: selectedAnnotationBoundingBox.midY - (viewSize / 2), width: viewSize, height: viewSize)
            let authorView = CustomOverlayLabelView(authorName: authorName, pageView: pageView, pdfRect: authorViewRect)

            // Add the custom overlay view to the page view.
            pageView.addSubview(authorView)

            // Remove the existing author view in case the current annotation is selected without
            // de-selecting the earlier annotation
            self.displayingCustomOverlayView?.removeFromSuperview()

            // Store a reference to the author view to remove it from the view when an annotation is
            // deselected.
            self.displayingCustomOverlayView = authorView
        }

        // `deselectAnnotation.addActivationCallback` code block is called whenever a user de-selects an annotation.
        self.interactions.deselectAnnotation.addActivationCallback { _, _, _ in
            // Remove the view as the annotation is no longer in selection.
            self.displayingCustomOverlayView?.removeFromSuperview()
        }
    }
}

/// A view containing a `UILabel` that can be added to a `PDFPageView`.
private class CustomOverlayLabelView: UIView {

    let pdfRect: CGRect
    weak var pageView: PDFPageView?

    let authorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Creates and returns a view that contains a label that can be added to a `PDFPageView`.
    /// - Parameters:
    ///   - authorName: Text to be displayed in the contained label.
    ///   - pageView: Page view to which this view is added.
    ///   - pdfRect: `CGRect` in PDF Page coordinates where the custom view is supposed to be placed.
    ///   Will be converted to the `pageView`'s coordinate space before using it as the `frame`.
    init(authorName: String, pageView: PDFPageView, pdfRect: CGRect) {
        self.pageView = pageView
        self.pdfRect = pdfRect

        // Convert the rect from PDF Page Coordinates to PageView coordinates.
        let viewRect = pageView.convert(pdfRect, from: pageView.pdfCoordinateSpace)
        super.init(frame: viewRect)

        addSubview(authorLabel)
        NSLayoutConstraint.activate([
            authorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            authorLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        authorLabel.text = authorName

        // Use black text color here because the page background is light
        // and to ensure the text visibility in both light and dark mode.
        authorLabel.textColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
