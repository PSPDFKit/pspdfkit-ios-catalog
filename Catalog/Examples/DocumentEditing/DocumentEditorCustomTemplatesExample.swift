//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DocumentEditorCustomTemplatesExample: Example {
    override init() {
        super.init()
        title = "Add New Page from Custom Template"
        contentDescription = "Use custom templates to add new pages to a document."
        category = .documentEditing
        priority = 3
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

    class EditingPDFController: PDFViewController, PDFNewPageViewControllerDelegate {
        // MARK: Actions

        @objc func edit(_ sender: AnyObject) {
            let url = AssetLoader.document(for: .about).fileURL!
            let document = Document(url: url)
            let customTemplate = PageTemplate(document: document, sourcePageIndex: 0)
            let newPageViewController = PDFNewPageViewController(documentEditorConfiguration: PDFDocumentEditor.Configuration {
                $0.pageTemplates.append(contentsOf: [customTemplate])
            })
            newPageViewController.delegate = self
            newPageViewController.modalPresentationStyle = .popover

            let options = [.inNavigationController: true, .closeButton: true] as [PresentationOption: Any]
            present(newPageViewController, options: options, animated: true, sender: sender)
        }

        func newPageController(_ controller: PDFNewPageViewController, didFinishSelecting configuration: PDFNewPageConfiguration?, pageCount: PageCount) {
            dismiss(animated: true, completion: nil)

            guard let document = document, let configuration = configuration, let editor = PDFDocumentEditor(document: document) else { return }

            editor.addPages(in: NSRange(location: 0, length: 1), with: configuration)

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
