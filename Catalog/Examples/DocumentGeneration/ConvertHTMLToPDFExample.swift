//
//  Copyright © 2018-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

//  MIT License (MIT) for Simple HTML invoice template: https://github.com/sparksuite/simple-html-invoice-template/blob/master/LICENSE

#if !targetEnvironment(macCatalyst)

class ConvertHTMLToPDFExample: Example {

    override init() {
        super.init()

        title = "Convert HTML to PDF"
        contentDescription = "Convert a URL or simple HTML to PDF."
        category = .documentGeneration
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let htmlFileURL = AssetLoader.assetURL(for: "Invoice.html")
        let htmlString = try! String(contentsOf: htmlFileURL, encoding: .utf8)
        let outputURL = FileHelper.temporaryPDFFileURL(prefix: "converted")

        // start the conversion
        let status = StatusHUDItem.indeterminateProgress(withText: "Converting...")
        status.setHUDStyle(.black)
        status.push(animated: true, on: delegate.currentViewController?.view.window, completion: nil)

        let options = [PSPDFProcessorNumberOfPagesKey: 1, PSPDFProcessorDocumentTitleKey: "Generated PDF"] as [String: Any]

        // You can also generate a PDF directly from a website URL.
        // Use the `Processor.generatePDF(from:outputFileURL:options:completionBlock:)` API instead of the below used API.
        // The only difference is that the above mentioned API takes a URL instance as a source
        // while the other takes a HTML string.
        // Uncomment and comment the below lines to see it in action.
        // Processor.generatePDF(from: URL(string: "https://www.nutrient.io/")!, outputFileURL: outputURL, options: options) { actualOutputURL, error in
        Processor.generatePDF(fromHTMLString: htmlString, outputFileURL: outputURL, options: options) { actualOutputURL, error in
            if let error {
                // Update status to error.
                let statusError = StatusHUDItem.error(withText: error.localizedDescription)
                statusError.pushAndPop(withDelay: 2, animated: true, on: delegate.currentViewController?.view.window)
                status.pop(animated: true)
            } else if let actualOutputURL {
                // Update status to done.
                let statusDone = StatusHUDItem.success(withText: "Done")
                statusDone.pushAndPop(withDelay: 2, animated: true, on: delegate.currentViewController?.view.window)
                status.pop(animated: true)
                // Generate document and show it.
                let document = Document(url: actualOutputURL)
                let pdfController = PDFViewController(document: document)
                delegate.currentViewController!.navigationController?.pushViewController(pdfController, animated: true)
            }
        }
        return nil
    }
}

#endif
