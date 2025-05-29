//
//  Copyright © 2017-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class OpenInExample: Example, PDFDocumentPickerControllerDelegate {
    override init() {
        super.init()

        title = "Open In… Inbox"
        contentDescription = "Displays all files in the Inbox directory via the PDFDocumentPickerController."
        category = .top
        priority = 6
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Add all documents in the Documents folder and subfolders (e.g. Inbox from Open In... feature)
        let documentSelector = PDFDocumentPickerController(directory: nil, includeSubdirectories: true, library: SDK.shared.library)
        documentSelector.delegate = self
        documentSelector.fullTextSearchEnabled = true
        documentSelector.title = self.title
        return documentSelector
    }

     func documentPickerController(_ controller: PDFDocumentPickerController, didSelect document: Document, pageIndex: PageIndex, search searchString: String?) {
        let pdfController = AdaptivePDFViewController(document: document)
        pdfController.pageIndex = pageIndex
        controller.navigationController?.pushViewController(pdfController, animated: true)
    }
}
