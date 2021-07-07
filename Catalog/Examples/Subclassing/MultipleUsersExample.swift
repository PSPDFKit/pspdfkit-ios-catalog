//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class MultipleUsersExample: Example {

    override init() {
        super.init()

        title = "Store annotations in JSON files for multiple users"
        contentDescription = "Shows how to store annotations in JSON files for multiple users"
        category = .subclassing
        priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .JKHF)
        let controller = MultipleUsersPDFViewController(document: document)
        return controller
    }
}

private class MultipleUsersPDFViewController: PDFViewController {

    private func withFirstProvider<T>(of document: Document, perform: (PDFDocumentProvider) -> T ) -> T {
        return perform(document.documentProviders.first!)
    }

    private(set) var currentUsername: String = "" {
        didSet {
            guard oldValue != currentUsername else { return }

            let document = self.document!

            // Forward to the document
            document.defaultAnnotationUsername = currentUsername

            guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

            let oldInstantJSONFile = documentsUrl.appendingPathComponent("\(oldValue).json", isDirectory: false)
            let currentInstantJSONFile = documentsUrl.appendingPathComponent("\(currentUsername).json", isDirectory: false)

            // Save the previous user's annotation into its own JSON file.
            let oldJsonData = withFirstProvider(of: document) {
                return try! document.generateInstantJSON(from: $0)
            }
            try? oldJsonData.write(to: oldInstantJSONFile, options: Data.WritingOptions.atomic)

            // Then clear the document cache
            document.clearCache()

            // Load the annotations of the current users into the document.
            guard let newJsonData = try? Data(contentsOf: currentInstantJSONFile) else { return }

            let jsonContainer = DataContainerProvider(data: newJsonData)
            withFirstProvider(of: document) {
                try! document.applyInstantJSON(fromDataProvider: jsonContainer, to: $0, lenient: false)
            }

            // And finally - reload the PDF.
            reloadData()
        }
    }

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        // Set a test user.
        self.currentUsername = "Testuser"

        // Customize the toolbar.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        updateCustomToolbar()
        documentInfoCoordinator.availableControllerOptions = [DocumentInfoOption.annotations]
        navigationItem.rightBarButtonItems = [thumbnailsButtonItem, outlineButtonItem, annotationButtonItem]
    }

    // MARK: - Private

    private func updateCustomToolbar() {
        let switchUserButtonItem = UIBarButtonItem(title: "User: \(currentUsername)", style: .plain, target: self, action: #selector(switchUser(_:)))
        navigationItem.leftBarButtonItems = [closeButtonItem, switchUserButtonItem]
    }

    @objc func switchUser(_ sender: UIBarButtonItem) {
        // Dismiss any popovers.
        dismissViewController(of: nil, animated: true)

        let alertController = UIAlertController(title: "Switch User", message: "Enter username.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = self.currentUsername
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Switch", style: .default, handler: { [unowned self] _ in
            // In a real application you want to make the username unique and also check for characters that are trouble on file systems.
            guard let username = alertController.textFields?.first?.text else { return }
            // Set new username
            self.currentUsername = username
            // Update toolbar to show new name.
            self.updateCustomToolbar()
        }))

        present(alertController, animated: true, completion: nil)
    }
}
