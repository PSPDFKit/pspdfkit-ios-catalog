//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class FullTextSearchExample: Example, PDFDocumentPickerControllerDelegate {
    override init() {
        super.init()
        title = "Full-Text Search"
        contentDescription = "Use PDFDocumentPickerController to perform a full-text search across all sample documents."
        category = .textExtraction
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        // Load the `PDFDocumentPickerController` with a directory of documents to index and an instance of a `PDFLibrary` to use.
        // Also, see https://pspdfkit.com/guides/ios/features/indexed-full-text-search/
        let documentPicker = PDFDocumentPickerController(directory: "/Bundle/Samples", includeSubdirectories: true, library: SDK.shared.library)
        documentPicker.delegate = self
        documentPicker.fullTextSearchEnabled = true
        return documentPicker
    }

    // MARK: - PDFDocumentPickerControllerDelegate
    func documentPickerController(_ controller: PDFDocumentPickerController, didSelect document: Document, pageIndex: PageIndex, search searchString: String?) {
        let pdfController = PDFViewController(document: document)
        pdfController.pageIndex = pageIndex
        pdfController.navigationItem.setRightBarButtonItems([pdfController.thumbnailsButtonItem, pdfController.annotationButtonItem, pdfController.outlineButtonItem, pdfController.searchButtonItem], for: .document, animated: false)

        controller.navigationController?.pushViewController(pdfController, animated: true)
    }
}
