//
//  Copyright © 2016-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class NewPageFromDocumentExample: Example {

    override init() {
        super.init()
        title = "Copy Page From Another Document"
        contentDescription = "Use PSPDFDocumentEditor to copy a page from another document."
        category = .documentEditing
        priority = 3
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Let's create a new writable document every time we invoke the example.
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: true)
        let pdfController = EditingPDFController(document: document)

        // Add a single button that triggers preset document editing actions.
        let editButtonItem = UIBarButtonItem(image: SDK.imageNamed("document_editor"), style: .plain, target: pdfController, action: #selector(EditingPDFController.edit))
        pdfController.navigationItem.rightBarButtonItems = [editButtonItem]

        return pdfController
    }

    // MARK: Controller

    class EditingPDFController: PDFViewController {

        // MARK: Actions

        @objc func edit(_ sender: AnyObject) {
            guard let document else { return }
            guard let editor = PDFDocumentEditor(document: document) else { return }

            let anotherDocument = AssetLoader.document(for: "Placeholder A.pdf")

            // Copy page from another document
            let template = PageTemplate(document: anotherDocument, sourcePageIndex: 0)
            let newPageConfiguration = PDFNewPageConfiguration(pageTemplate: template, builderBlock: nil)
            editor.addPages(in: NSRange(location: 0, length: 1), with: newPageConfiguration)

            // Save and overwrite the document.
            editor.save { _, error in
                if let error {
                    print("Document editing failed: \(error)")
                    return
                }

                // Access the UI on the main thread.
                DispatchQueue.main.async {
                    self.pdfController.reloadData()
                }
            }
        }
    }
}
