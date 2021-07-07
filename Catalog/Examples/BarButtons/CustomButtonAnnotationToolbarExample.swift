//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomButtonAnnotationToolbarExample: Example {

    override init() {
        super.init()
        title = "Add a Custom Button to the Annotation Toolbar"
        contentDescription = "Will add a 'Clear' button to the annotation toolbar that removes all annotations from the visible page."
        category = .barButtons
        priority = 210
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .annualReport)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(AnnotationToolbar.self, with: AnnotationToolbarWithClearButton.self)
        }
        return controller
    }
}

class AnnotationToolbarWithClearButton: AnnotationToolbar, PDFDocumentViewControllerDelegate {
    var clearAnnotationsButton: ToolbarButton

    // MARK: - Lifecycle
    override init(annotationStateManager: AnnotationStateManager) {
        clearAnnotationsButton = ToolbarButton()
        clearAnnotationsButton.accessibilityLabel = "Clear"
        clearAnnotationsButton.image = SDK.imageNamed("trash")!.withRenderingMode(.alwaysTemplate)

        super.init(annotationStateManager: annotationStateManager)

        // The biggest challenge here isn't the clear button, but correctly updating the clear button if we actually can clear something or not.
        let dnc = NotificationCenter.default
        dnc.addObserver(self, selector: #selector(annotationChangedNotification(_:)), name: NSNotification.Name.PSPDFAnnotationChanged, object: nil)
        dnc.addObserver(self, selector: #selector(annotationChangedNotification(_:)), name: NSNotification.Name.PSPDFAnnotationsAdded, object: nil)
        dnc.addObserver(self, selector: #selector(annotationChangedNotification(_:)), name: NSNotification.Name.PSPDFAnnotationsRemoved, object: nil)

        // Set document view controller delegate to get notified when the page changes.
        annotationStateManager.pdfController?.documentViewController?.delegate = self

        // Add clear button
        clearAnnotationsButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        updateClearAnnotationButton()
        additionalButtons = [clearAnnotationsButton]
    }

    // MARK: - Clear Button Action
    @objc func clearButtonPressed() {
        guard let pdfController = annotationStateManager.pdfController,
              let document = pdfController.document else {
            return
        }
        // Iterate over all visible pages and remove all editable annotations.
        for pageView in pdfController.visiblePageViews {
            let annotations = document.annotationsForPage(at: pageView.pageIndex, type: editablAnnotationKind)
            document.remove(annotations: annotations)

            // Remove any annotation on the page as well (updates views).
            // Alternatively, you can call `reloadData` on the pdfController.
            for annotation in annotations {
                pageView.remove(annotation, options: nil, animated: true)
            }
        }
    }

    // MARK: - Notifications

    // If we detect annotation changes, schedule a reload.
    @objc func annotationChangedNotification(_ notification: Notification?) {
        // Re-evaluate toolbar button
        if window != nil {
            updateClearAnnotationButton()
        }
    }

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeUndoState undoEnabled: Bool, redoState redoEnabled: Bool) {
        super.annotationStateManager(manager, didChangeUndoState: undoEnabled, redoState: redoEnabled)
        updateClearAnnotationButton()
    }

    // MARK: - Delegate

    func documentViewController(_ documentViewController: PDFDocumentViewController, willBeginDisplaying spreadView: PDFSpreadView, forSpreadAt spreadIndex: Int) {
        updateClearAnnotationButton()
    }

    func documentViewController(_ documentViewController: PDFDocumentViewController, didEndDisplaying spreadView: PDFSpreadView, forSpreadAt spreadIndex: Int) {
        updateClearAnnotationButton()
    }

    // MARK: - Private

    private func updateClearAnnotationButton() {
        guard let pdfController = annotationStateManager.pdfController else {
            return
        }
        let containsAnnotations = pdfController.visiblePageIndexes.contains { index in
            let annotations = pdfController.document?.annotationsForPage(at: PageIndex(index), type: editablAnnotationKind) ?? []
            return !annotations.isEmpty
        }

        clearAnnotationsButton.isEnabled = containsAnnotations
    }

    private var editablAnnotationKind: Annotation.Kind {
        var kind = Annotation.Kind.all
        kind.remove(.link)
        kind.remove(.widget)
        return kind
    }
}
