//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

// This example does not show asking for the annotation username. Normally the user is asked the first time they press the annotation button. Instead, you may want to use `UsernameHelper` to set this before showing the PDF view controller.

class AlwaysShowAnnotationToolbarExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Always show annotation toolbar"
        contentDescription = "Keep the annotation toolbar visible instead of it being toggled by the annotation button in the main toolbar."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        // We can’t directly show the annotation toolbar in this function because this must
        // be done after the view hierarchy has been set up. Therefore use a subclass of the
        // PDF view controller that shows the annotation toolbar on appearing.
        let controller = ShowAnnotationToolbarPDFViewController(document: document) {
            // Use subclass of the annotation toolbar that hides the X button.
            $0.overrideClass(AnnotationToolbar.self, with: NoDoneButtonAnnotationToolbar.self)
        }

        // Remove the button from the main toolbar that normally toggles annotation toolbar visibility.
        var items = controller.navigationItem.rightBarButtonItems(for: .document) ?? []
        if let index = items.firstIndex(of: controller.annotationButtonItem) {
            items.remove(at: index)
        }
        controller.navigationItem.setRightBarButtonItems(items, for: .document, animated: false)

        // Don’t allow the annotation toolbar to cover the navigation bar. Only allow it on the left or right.
        // The force unwrap is safe as long as the annotations feature is enabled in the Nutrient license.
        controller.annotationToolbarController!.annotationToolbar.supportedToolbarPositions = .vertical

        // Since the annotation toolbar is hidden when going into the thumbnails view mode, we
        // register for callbacks so we can show it when going back to the document view mode.
        controller.delegate = self

        return controller
    }

    func pdfViewController(_ pdfController: PDFViewController, didChange viewMode: ViewMode) {
        // Since the annotation toolbar is hidden when going into the thumbnails
        // view mode, make it visible again when exiting that view mode.
        if viewMode == .document {
            pdfController.ensureAnnotationToolbarIsVisible(animated: true)
        }
    }
}

/// Nutrient PDFViewController that shows the annotation toolbar when the view appears.
private class ShowAnnotationToolbarPDFViewController: PDFViewController {

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        ensureAnnotationToolbarIsVisible(animated: false)
    }
}

private extension PDFViewController {

    func ensureAnnotationToolbarIsVisible(animated: Bool) {
        // The force unwrap is safe as long as the annotations feature is enabled in the Nutrient license.
        annotationToolbarController!.updateHostView(nil, container: nil, viewController: self)
        annotationToolbarController!.showToolbar(animated: animated)
    }
}

/// Nutrient annotation toolbar without the X button.
private class NoDoneButtonAnnotationToolbar: AnnotationToolbar {

    override var doneButton: UIButton? {
        nil
    }
}
