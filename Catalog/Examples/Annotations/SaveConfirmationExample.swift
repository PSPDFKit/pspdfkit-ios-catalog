//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class SavePermissionExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Save permission alert before closing"
        category = .annotations
        priority = 400
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        /*
         Note: Having auto saving of a document disabled and asking to save before exiting isn't a 100% reliable approach on iOS approach, since the app can always be closed using the multitasking switcher, where this action will not be called, resulting in loss of the made changes.
         */
        let controller = SavePermissionViewController(document: document) {
            // Disable autosaving of the PDF.
            $0.isAutosaveEnabled = false
        }
        return controller
    }
}

private class SavePermissionViewController: PDFViewController {

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        let exitButton = UIBarButtonItem(title: "Exit", style: .done, target: self, action: #selector(exit))

        // Add custom exit button that shows the alert controller when tapped
        self.navigationItem.leftBarButtonItems = [exitButton]
    }

    @objc func exit() {
        // Check if the document has any changes or not. Exit immediately if it doesn't.
        guard let document = self.document, document.hasDirtyAnnotations == true else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }

        let alertController = UIAlertController(title: nil, message: "Do you want to save the changes made to the document?", preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let document = self.document else { return }
            // Manually save the document and exit after saving
            document.save { _ in
                self.navigationController?.popViewController(animated: true)
            }
        }
        let exitAction = UIAlertAction(title: "Exit without save", style: .destructive) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(exitAction)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
