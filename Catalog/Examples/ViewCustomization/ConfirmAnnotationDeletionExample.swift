//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class ConfirmAnnotationDeletionExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()
        title = "Confirm Annotation Deletion"
        contentDescription = "Shows how to present a confirmation sheet before deleting annotations."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        PDFViewController(document: AssetLoader.document(for: .JKHF), delegate: self)
    }

    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, for annotations: [Annotation]?, in annotationRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        // Show only if there's at least one annotation selected. This delegate
        // method is also used for the annotation creation menu, in which case
        // the annotations array will be empty.
        guard let annotations = annotations, !annotations.isEmpty else {
            return menuItems
        }
        // Search for the deletion item. Its title is localized so we must use
        // the identifier. Deletion is unavailable for some annotation types
        // (e.g. form elements) so don't assume it's always there.
        if let removeItem = menuItems.first(where: { $0.identifier == TextMenu.annotationMenuRemove.rawValue }) {
            // Save the original action block for later reuse.
            let originalActionBlock = removeItem.actionBlock
            // Menu items are saved in a global object so it's recommended to
            // not retain strong references in their action blocks.
            removeItem.actionBlock = { [weak pdfController] in
                let alert = UIAlertController(
                    // A custom localization dictionary must be used for correct
                    // localization. Some languages have more forms of
                    // pluralization than English.
                    title: annotations.count == 1 ? "Delete annotation?" : "Delete \(annotations.count) annotations?",
                    message: nil,
                    preferredStyle: .actionSheet
                )
                alert.addAction(.init(
                    title: "Cancel",
                    style: .cancel
                ))
                alert.addAction(.init(
                    title: "Delete",
                    style: .destructive,
                    handler: { _ in
                        originalActionBlock()
                    }
                ))
                // Present as popover on iPad.
                alert.popoverPresentationController?.sourceRect = rect
                alert.popoverPresentationController?.sourceView = pageView
                pdfController?.present(alert, animated: true)
            }
        }
        return menuItems
    }

}
