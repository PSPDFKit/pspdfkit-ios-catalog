//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class BooksHighlightingExample: Example {

    override init() {
        super.init()
        title = "Highlighting like in Apple Books"
        contentDescription = "Shows how to automatically create a highlight annotation after selecting text, replicating the behavior of Apple Books app."
        category = .controllerCustomization
        priority = 25
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        CustomPDFViewController(document: AssetLoader.writableDocument(for: .JKHF, overrideIfExists: true))
    }

}

private class CustomPDFViewController: PDFViewController, UIGestureRecognizerDelegate {

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration.configurationUpdated { builder in
            // Disable the menu that allows to create annotations.
            builder.isCreateAnnotationMenuEnabled = false
            // Don't show text selection handles.
            builder.textSelectionMode = .simple
        })
        // Remove annotationButtonItem since we only want highlight annotations,
        // and these are created without going into special mode.
        navigationItem.setRightBarButtonItems([thumbnailsButtonItem, activityButtonItem, outlineButtonItem, searchButtonItem], for: .document, animated: false)
        // Enable the highlighting mode for Apple Pencil.
        annotationStateManager.state = .highlight
        annotationStateManager.stylusMode = .stylus
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Add a custom gesture recognizer so that we can independently track
        // when a touch begins and ends.
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognizerDidChangeState))
        recognizer.minimumPressDuration = 0
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
    }

    // A flag that tells whether we're tracking a fresh text selection or not.
    private var isFreshSelection = false

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Let our gesture recognizer work "in background" and not interfere
        // with any other gesture recognizer.
        true
    }

    @objc private func longPressGestureRecognizerDidChangeState(_ recognizer: UILongPressGestureRecognizer) {
        // Don't process touches outside of page views.
        guard let pageView = documentViewController?.visiblePageView(at: recognizer.location(in: documentViewController?.view)) else {
            return
        }
        // Track when a new text selection begins.
        if recognizer.state == .began {
            isFreshSelection = pageView.selectionView.selectedGlyphs.isEmpty
            return
        }
        // Make sure that we're tracking a fresh text selection.
        if recognizer.state == .ended, isFreshSelection, !pageView.selectionView.selectedGlyphs.isEmpty {
            // Create a highlight annotation.
            let highlight = HighlightAnnotation.textOverlayAnnotation(with: pageView.selectionView.selectedGlyphs)!
            highlight.pageIndex = pageView.pageIndex
            document?.add(annotations: [highlight])
            // Wait until touch processing completes in the event loop cycle.
            // Modifying selection directly in this method, while PSPDFKit is
            // still processing touches internally, will lead to bad behavior.
            DispatchQueue.main.async {
                pageView.selectionView.discardSelection(animated: false)
                pageView.selectedAnnotations = [highlight]
                pageView.showMenuIfSelected(animated: true)
            }
        }
    }

}
