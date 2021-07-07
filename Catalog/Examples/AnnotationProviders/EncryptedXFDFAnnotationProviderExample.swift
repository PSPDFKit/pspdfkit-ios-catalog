//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class EncryptedXFDFAnnotationProviderExample: Example {

    override init() {
        super.init()
        title = "XFDF Annotation Provider, Encrypted"
        contentDescription = "Variant that encrypts/decrypts the XFDF file on-the-fly."
        category = .annotationProviders
        priority = 81
    }

    // This example shows how you can create an XFDF provider instead of the default file-based one.
    // XFDF is an industry standard and the file will be interopable with Adobe Acrobat or any other standard-compliant PDF framework.
    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let documentURL = AssetLoader.assetURL(for: .JKHF)

        // Load from an example XFDF file.
        let passphraseProvider = { () -> String in
            return "jJ9A3BiMXoq+rEoYMdqBoBNzgxagTf"
        }

        let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileXML = docsFolder.appendingPathComponent("XFDFTest-encrypted.xfdf")
        print("Using XFDF file at \(fileXML.path)")

        // DEBUG HELPER: delete existing file.
        // try? FileManager.default.removeItem(at: fileXML)

        // Create an example XFDF from the current document if one doesn't already exist.
        if !FileManager.default.fileExists(atPath: fileXML.path) {
            // Collect all existing annotations from the document
            let tempDocument = Document(url: documentURL)
            let annotations = tempDocument.allAnnotations(of: .all).values.flatMap { $0 }

            // Write the annotations to the disk creating a new XFDF file.
            let dataSink = AESCryptoDataSink(url: fileXML, passphraseProvider: passphraseProvider)
            do {
                try XFDFWriter().write(annotations, to: dataSink, documentProvider: tempDocument.documentProviders.first!)
            } catch {
                print("Failed to write XFDF file: \(error.localizedDescription)")
            }
        }

        guard let cryptoDataProvider = AESCryptoDataProvider(url: fileXML, passphraseProvider: passphraseProvider) else {
            print("Error creating crypto data provider")
            return nil
        }

        // Create document and set up the XFDF provider.
        let document = Document(url: documentURL)
        document.annotationSaveMode = .externalFile
        document.didCreateDocumentProviderBlock = { documentProvider in
            let XFDFProvider = XFDFAnnotationProvider(documentProvider: documentProvider, dataProvider: cryptoDataProvider)
            // Note that if the document you're opening has form fields which you wish to be usable when using XFDF, you should also add the file annotation
            // provider to the annotation manager's `annotationProviders` array:
            //
            // let fileProvider = documentProvider.annotationManager.fileAnnotationProvider!
            // documentProvider.annotationManager.annotationProviders = [XFDFProvider, fileProvider]

            documentProvider.annotationManager.annotationProviders = [XFDFProvider]
        }

        return PDFViewController(document: document)
    }
}
