//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit
import PSPDFKitUI

class AddFileAnnotationWithEmbeddedFileExample: Example, PDFViewControllerDelegate, PDFDocumentPickerControllerDelegate {

    var pdfController: PDFViewController?
    var documentPickerController: PDFDocumentPickerController?
    var longPressedPoint: CGPoint?

    override init() {
        super.init()

        title = "Add and remove file annotations with embedded files from a custom menu item"
        contentDescription = "Adds new menu items that will create and delete file annotations at the selected position."
        category = .annotations
        priority = 65
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        documentPickerController = PDFDocumentPickerController(directory: "/Bundle/Samples", includeSubdirectories: true, library: SDK.shared.library)
        documentPickerController?.delegate = self

        pdfController = PDFViewController(document: document)
        pdfController?.delegate = self
        return pdfController!
    }

    // MARK: - PDFViewControllerDelegate

    internal func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, for annotations: [Annotation]?, in annotationRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        var allMenuItems: [MenuItem] = menuItems
        // Long pressed on the page view.
        if annotations == nil {
            let attachFileMenuItem = MenuItem(title: "Attach File") {
                // Store the long pressed point in PDF coordinates to be used to set the bounding box of the newly created file annotation.
                self.longPressedPoint = pageView.convert(rect, to: pageView.pdfCoordinateSpace).origin
                // Present the document picker.
                self.pdfController?.present(self.documentPickerController!, options: [.closeButton: true], animated: true, sender: nil, completion: nil)
            }
            // Add the new menu item to be the first (leftmost) item.
            allMenuItems.insert(attachFileMenuItem, at: 0)
        } else { // Tapped on one or more annotations.
            let fileAnnotations = annotations?.compactMap { $0 as? FileAnnotation }
            // If one of the selected annotations is a file annotation, so we add the delete menu item to delete all selected annotations.
            if fileAnnotations?.isEmpty == false {
                let deleteFileMenuItem = MenuItem(title: "Delete Attachment", image: SDK.imageNamed("trash"), block: {
                    // Only remove selected annotations.
                    pdfController.document?.remove(annotations: annotations!)
                }, identifier: "Delete Attachment")
                // Add the new menu item last, to be the leftmost item.
                allMenuItems.append(deleteFileMenuItem)
            }
        }
        return allMenuItems
    }

    // MARK: - PDFDocumentPickerControllerDelegate

    func documentPickerController(_ controller: PDFDocumentPickerController, didSelect document: Document, pageIndex: PageIndex, search searchString: String?) {
        let fileURL = document.fileURL
        let fileDescription = document.fileURL?.lastPathComponent

        // Create the file annotation and its embedded file
        let fileAnnotation = FileAnnotation()
        fileAnnotation.pageIndex = pageIndex
        fileAnnotation.boundingBox = CGRect(x: (self.longPressedPoint?.x)!, y: (self.longPressedPoint?.y)!, width: 32, height: 32)
        let embeddedFile = EmbeddedFile(fileURL: fileURL!, fileDescription: fileDescription)
        fileAnnotation.embeddedFile = embeddedFile

        // Add the embedded file to the document.
        pdfController?.document?.add(annotations: [fileAnnotation])

        // Dismiss the document picker.
        controller.dismiss(animated: true, completion: nil)
    }
}
