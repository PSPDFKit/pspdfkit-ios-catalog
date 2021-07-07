//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class ProgrammaticDocumentEditingExample: Example {

    override init() {
        super.init()
        title = "Programmatic Document Editing"
        contentDescription = "Use PSPDFDocumentEditor to update the current document."
        category = .documentEditing
        priority = 2
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Let's create a new writable document every time we invoke the example.
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)
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
            guard let document = document else { return }
            guard let editor = PDFDocumentEditor(document: document) else { return }

            // Rotate first two pages 90 degree.
            editor.rotatePages([0, 1], rotation: 90)

            // Add a new page as the first page.
            let newPageConfiguration = PDFNewPageConfiguration(pageTemplate: PageTemplate(pageType: .tiledPatternPage, identifier: .grid5mm)) {
                $0.pageSize = document.pageInfoForPage(at: 0)!.size
                $0.backgroundColor = UIColor.psc_secondarySystemBackground
            }
            editor.addPages(in: NSRange(location: 0, length: 1), with: newPageConfiguration)

            // Save and overwrite the document.
            editor.save { _, error in
                if let error = error {
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
