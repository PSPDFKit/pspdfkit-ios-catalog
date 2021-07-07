//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class XFDFAnnotationProviderEmbeddedExample: Example {

    override init() {
        super.init()
        title = "XFDF Annotation Provider - Generate new file"
        contentDescription = "Generating a new file with XFDF annotations using PSPDFProcessor"
        category = .annotationProviders
        priority = 90
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let documentURL = AssetLoader.assetURL(for: .JKHF)

        let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = docsFolder.appendingPathComponent("OutputJKHFAsset.pdf")

        // Load from an example XFDF file.
        let fileXML = docsFolder.appendingPathComponent("XFDFTest.xfdf")
        print("Using XFDF file at \(fileXML.path)")

        // Create document and set up the XFDF provider.
        let document = Document(url: documentURL)
        document.didCreateDocumentProviderBlock = { documentProvider in
            let XFDFProvider = XFDFAnnotationProvider(documentProvider: documentProvider, fileURL: fileXML)
            // Note that if the document you're opening has form fields which you wish to be usable when using XFDF, you should also add the file annotation
            // provider to the annotation manager's `annotationProviders` array:
            //
            // let fileProvider = documentProvider.annotationManager.fileAnnotationProvider!
            // documentProvider.annotationManager.annotationProviders = [XFDFProvider, fileProvider]

            documentProvider.annotationManager.annotationProviders = [XFDFProvider]
        }

        let controller = PDFViewController(document: document)

        let saveButton = UIBarButtonItem(title: "Save", style: .plain) { _ in
            // Generate a new document with embedded annotations
            let config = Processor.Configuration(document: document)!
            config.modifyAnnotations(ofTypes: .all, change: .embed)

            // The processor doesn't overwrite files, so we remove the document.
            try? FileManager.default.removeItem(at: outputURL)

            let processor = Processor(configuration: config, securityOptions: nil)
            do {
                try processor.write(toFileURL: outputURL)
                print("Saved file to: \(outputURL)")
            } catch {
                print("Failed saving file to: \(outputURL). Error: \(error.localizedDescription)")
            }
        }
        controller.navigationItem.leftBarButtonItems = [controller.closeButtonItem, saveButton]
        return controller
    }
}
