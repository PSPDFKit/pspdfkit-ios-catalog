//
//  Copyright © 2017-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CreatePasswordProtectedDocumentExample: Example {

    override init() {
        super.init()
        title = "Create password protected PDF"
        contentDescription = "Password is 'test123'"
        category = .security
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let password = "test123"
        let tempURL = FileHelper.temporaryPDFFileURL(prefix: "protected")
        let hackerMagDoc = AssetLoader.document(for: .annualReport)
        let status = StatusHUDItem.progress(withText: PSPDFKit.localizedString("Preparing") + ("…"))
        status.push(animated: true, on: delegate.currentViewController?.view.window)

        // By default, a newly initialized `PSPDFProcessorConfiguration` results in an exported Document that is the same as the input.
        let processorConfiguration = Processor.Configuration(document: hackerMagDoc)

        // Set the proper password and key length in the `Document.SecurityOptions`
        let documentSecurityOptions = try? Document.SecurityOptions(ownerPassword: password, userPassword: password, keyLength: Document.SecurityOptionsKeyLengthAutomatic)

        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            do {
                // Process annotations.
                // `PSPDFProcessor` doesn't modify the document, but creates an output file instead.
                let processor = Processor(configuration: processorConfiguration!, securityOptions: documentSecurityOptions)
                processor.delegate = self
                try processor.write(toFileURL: tempURL)
            } catch {
                print("Error while processing document: \(error)")
                return
            }
            DispatchQueue.main.async(execute: {() -> Void in
                status.pop(animated: true)
                // show file
                let document = Document(url: tempURL)
                let pdfController = PDFViewController(document: document)
                delegate.currentViewController?.navigationController?.pushViewController(pdfController, animated: true)
            })
        })
        return nil
    }
}

extension CreatePasswordProtectedDocumentExample: ProcessorDelegate {
    func processor(_ processor: Processor, didProcessPage currentPage: UInt, totalPages: UInt) {
        print("Progress: \(currentPage + 1) of \(totalPages)")
    }
}
