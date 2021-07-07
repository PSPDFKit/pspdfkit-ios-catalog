//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class CustomSharingOptionsExample: Example {

    var pdfController: PDFViewController!
    var document: Document!
    var otherDocument: Document!

    override init() {
        super.init()

        title = "Custom Sharing Options"
        contentDescription = "Customzies the sharing options for documents in different ways."
        category = .sharing
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        document = AssetLoader.document(for: .quickStart)
        otherDocument = AssetLoader.document(for: .annualReport)

        pdfController = PDFViewController(document: document)

        let shareButton = UIBarButtonItem(image: SDK.imageNamed("share"), style: .done, target: self, action: #selector(shareButtonTapped(sender:)))

        /// This button works similarly to that of exporting multiple documents,
        /// but the PDFDocumentSharingViewController delegate implemented below is called.
        /// In the delegate callback below, you can also access the files about to be exported.
        let onlyExportButton = UIBarButtonItem(title: "Only Export the Files", style: .done, target: self, action: #selector(CustomSharingOptionsExample.onlyExportFiles(sender:)))

        pdfController.navigationItem.rightBarButtonItems = [shareButton, onlyExportButton]
        return pdfController
    }

    @objc
    fileprivate func shareButtonTapped(sender: Any) {
        guard let sender = sender as? UIBarButtonItem else {
            return
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender

        // Add Email option
        let emailAction = UIAlertAction(title: "Email", style: .default) { _ in
            self.emailTapped(sender: sender)
        }
        alertController.addAction(emailAction)

        // Add Export option
        let exportAction = UIAlertAction(title: "Export", style: .default) { _ in
            self.exportTapped(sender: sender)
        }
        alertController.addAction(exportAction)

        // Add Multiple Documents option
        let multipleDocumentsAction = UIAlertAction(title: "Multiple Documents", style: .default) { _ in
            self.exportMultipleDocuments(sender: sender)
        }
        alertController.addAction(multipleDocumentsAction)

        // Cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        // Present the alert
        pdfController.present(alertController, animated: true)
    }

    @objc
    fileprivate func emailTapped(sender: Any) {
        let sharingConfiguration = DocumentSharingConfiguration {
            $0.destination = .email
            $0.annotationOptions.remove(.embed)
        }

        let shareController = PDFDocumentSharingViewController(documents: [document], sharingConfigurations: [sharingConfiguration])
        shareController.present(from: pdfController, sender: sender)
    }

    @objc
    fileprivate func exportTapped(sender: Any) {
        let sharingConfiguration = DocumentSharingConfiguration {
            $0.destination = .export
            $0.annotationOptions = [.flatten]
        }

        let shareController = PDFDocumentSharingViewController(documents: [document], sharingConfigurations: [sharingConfiguration])
        shareController.present(from: pdfController, sender: sender)
    }

    @objc
    fileprivate func exportMultipleDocuments(sender: Any) {
        let shareController = PDFDocumentSharingViewController(documents: [document, otherDocument])
        shareController.present(from: pdfController, sender: sender)
    }

    @objc
    fileprivate func onlyExportFiles(sender: Any) {
        let shareController = PDFDocumentSharingViewController(documents: [document, otherDocument])
        shareController.delegate = self
        shareController.present(from: pdfController, sender: sender)
    }
}

extension CustomSharingOptionsExample: PDFDocumentSharingViewControllerDelegate {
    internal func documentSharingViewController(_ shareController: PDFDocumentSharingViewController, shouldShare files: [File], toDestination destination: DocumentSharingConfiguration.Destination) -> Bool {
        pdfController.dismiss(animated: true, completion: nil)

        // Retrieve the files and copy them to a safe location

        return false
    }
}
