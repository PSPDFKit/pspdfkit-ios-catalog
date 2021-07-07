//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

class PrepareDocumentForContainedSignaturesExample: Example {

    override init() {
        super.init()
        title = "Prepare a document to embed a digital signature afterwards"
        category = .forms
        priority = 20
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Load a sample document with an already created signature form field.
        let document = AssetLoader.writableDocument(for: "Form_example.pdf", overrideIfExists: true)
        // We know this document must have a file URL because we are loading it from a file.
        let newURL = document.fileURL!

        // Now we get the signature form widget.
        let signatureFormElement = document.annotations(at: 0, type: SignatureFormElement.self).first!

        // During document preparation, we are able to configure a custom digital signature appearance.
        // We use an instance of a `PSPDFSignatureAppearance` to do that.
        let signatureAppearance = PDFSignatureAppearance {
            $0.appearanceMode = PDFSignatureAppearance.Mode.signatureAndDescription
            $0.showSigningDate = false
        }

        // Configure a data sink as destination.
        let dataSink = try! FileDataSink(fileURL: newURL, options: [])

        // Now configure the signer that will prepare the signature field. Configuring the "signersName" property
        // will customize the signer's name that will appear on the visual signature.
        let signer = PDFSigner()
        signer.signersName = "PSPDFKit GmbH"
        var preparedDocument: Document?

        // Typically, when preparing a document, we are not interested in what is inside the contents of the signature form field.
        // Passing an instance of a `PSPDFBlankSignatureContents` will fill the contents with zeroes.
        let signatureContents = BlankSignatureContents()
        signer.prepare(signatureFormElement, toBeSignedWith: signatureAppearance, contents: signatureContents, writingTo: dataSink) { (_ success: Bool, _ document: DataSink?, _ err: Error?) in
            let fileDataProvider = FileDataProvider(fileURL: newURL)
            do {
                try fileDataProvider.replaceContents(with: dataSink)
            } catch {
                print(error)
            }
            preparedDocument = Document(dataProviders: [fileDataProvider])
        }

        return PDFViewController(document: preparedDocument!)
    }
}

/// A sample `PSPDFSignatureContents` implementation that constructs a signature container from a binary file (.bin).
/// A real implementation would make use of the document byte range covered by a signature, hash it, encrypt it,
/// and return an hex-encoded PKCS7 container.
class BinaryFileSignatureContents: NSObject, PDFSignatureContents {
    func sign(_ dataToSign: Data) -> Data {
        return try! Data(contentsOf: self.signatureContentsPath)
    }

    init(signatureContentsPath: URL) {
        self.signatureContentsPath = signatureContentsPath
        super.init()
    }

    private let signatureContentsPath: URL
}

class EmebedContainedSignatureExample: Example {

    override init() {
        super.init()
        title = "Embed a digital signature in an already prepared PDF document"
        category = .forms
        priority = 21
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Load a sample document with a signature form field that was already prepared for signing.
        // See `PrepareDocumentForContainedSignaturesExample` to learn how to do that.
        let document = AssetLoader.writableDocument(for: "DocumentPreparedToBeSigned.pdf", overrideIfExists: true)
        let newURL = document.fileURL!

        // Now we get the signature form widget.
        let signatureFormElement = document.annotations(at: 0, type: SignatureFormElement.self).first!

        // The prepared signature is a .bin file that contains a PKCS7 signature for this document.
        let preparedSignatureSampleURL = AssetLoader.assetURL(for: "DocumentPreparedToBeSigned.bin")
        let signatureContents = BinaryFileSignatureContents(signatureContentsPath: preparedSignatureSampleURL)
        let dataSink = try! FileDataSink(fileURL: newURL, options: [])

        // Finally, create the signer and embed the PKCS7 signature in this document.
        let signer = PDFSigner()
        var preparedDocument: Document?
        signer.embedSignature(in: signatureFormElement, with: signatureContents, writingTo: dataSink) { (_ success: Bool, _ document: DataSink?, _ err: Error?) in
            let fileDataProvider = FileDataProvider(fileURL: newURL)
            do {
                try fileDataProvider.replaceContents(with: dataSink)
            } catch {
                print(error)
            }
            // Optionally, here you could make sure that the signed document is valid.
            // Read the `PSPDFSignatureValidator` documentation to learn how to do that.
            preparedDocument = Document(dataProviders: [fileDataProvider])
        }

        return PDFViewController(document: preparedDocument!)
    }
}
