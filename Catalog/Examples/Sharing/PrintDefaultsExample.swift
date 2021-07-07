//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class PrintDefaultsExample: Example {
    var pdfController: PDFViewController!

    override init() {
        super.init()
        title = "Customize the Printer Default Configuration"
        contentDescription = "Shows how to configure the printer default settings to print the annotation summary."
        category = .sharing
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        pdfController = PDFViewController(document: document)
        pdfController.printButtonItem.target = self
        pdfController.printButtonItem.action = #selector(printDocument(_:))
        pdfController.navigationItem.rightBarButtonItems = [pdfController.printButtonItem]
        return pdfController
    }

    @objc func printDocument(_ sender: Any?) {
        let customPrintConfiguration = DocumentSharingConfiguration.defaultConfiguration(forDestination: .print).configurationUpdated {
            $0.pageSelectionOptions = [.annotated]
            $0.annotationOptions = [.summary]
        }

        guard let document = pdfController.document else { return }
        let sharingViewController = PDFDocumentSharingViewController(documents: [document], sharingConfigurations: [customPrintConfiguration])
        sharingViewController.visiblePagesDataSource = pdfController
        sharingViewController.present(from: pdfController, sender: sender)
    }
}
