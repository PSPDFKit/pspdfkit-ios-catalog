//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DocumentEditorCustomSavingConfirmationExample: Example {
    override init() {
        super.init()
        title = "Customize the Saving Confirmation Alert on the Document Editor"
        contentDescription = "Provide custom options for saving a document after editing it."
        category = .viewCustomization
        priority = 3
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Let's create a new writable document every time we invoke the example.
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)
        let configuration = PDFConfiguration {
            $0.overrideClass(PDFDocumentEditorToolbarController.self, with: CustomEditorToolbarController.self)
        }

        return PDFViewController(document: document, configuration: configuration)
    }

    // MARK: Controller
    class CustomEditorToolbarController: PDFDocumentEditorToolbarController {
        override func savingConfirmationControllerForSender(_ sender: Any?, completionHandler: ((Bool) -> Void)? = nil) -> UIViewController {
            let newAlert = UIAlertController(title: "Save", message: "Are you sure you want to save?", preferredStyle: .actionSheet)

            newAlert.addAction(UIAlertAction(title: "Save As...", style: .default, handler: { [weak self] _ in
                self?.toggleSave(sender, presentationOptions: nil, completionHandler: completionHandler)
            }))

            newAlert.addAction(UIAlertAction(title: "Discard Changes", style: .destructive, handler: { [weak self] _ in
                self?.documentEditor?.reset()
                completionHandler?(false)
            }))

            newAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                completionHandler?(true)
            }))

            return newAlert
        }
    }
}
