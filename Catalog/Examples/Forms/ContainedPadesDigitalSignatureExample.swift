//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

/// The example here is similar to the `PrepareDocumentForContainedSignatureExample` example, only here we are preparing a
/// different signature type that will be written into the document during the embed phase (`EmebedContainedPadesSignatureExample`).
/// We are specifying the PDF advanced digital signature type "PAdES". This translates to the signature `SubFilter` value of
/// "ETSI.CAdES.detached" in the PDF.
///
/// Currently, we cannot write this signature type in the PDF, so this type can only work with "Contained" signatures, where the signature field is
/// prepared first and a valid PAdES signature is inserted into the `Contents` entry of the PDF signature dictionary.
///
/// Please refer to the ETSI standard for more information on PAdES signatures in PDF:
/// https://www.etsi.org/deliver/etsi_ts/119100_119199/11914403/01.01.01_60/ts_11914403v010101p.pdf
class PrepareDocumentForContainedPadesSignatureExample: Example {

    override init() {
        super.init()
        title = "Prepare a document to embed a PAdES advanced digital signature afterwards"
        category = .forms
        priority = 22
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
        // We also need to set the signature type to PAdES advanced for this example as the signature we
        // use in the signing step is PAdES compatible.
        signer.signatureType = .pades

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

/// This example takes the previously prepared "Form_Example.pdf" in the `PrepareDocumentForContainedPadesSignatureExample` above,
/// which contains space for a PAdES signature, and embeds a PAdES signature we have generated with external tools.
///
/// The signature was generated using some external tools using the following steps:
/// - Create a prepared document using the process detailed in the example above.
/// - Using this document, sign using the `esig`Java tool here: https://github.com/esig
/// An alternative is to use the iText signatures tool here: https://github.com/itext/i7js-signatures
/// - With the signed document, the signature `Contents` can be copied and dumped into a hex file:
/// `$ xxd -r -p signatureContents.txt output.bin`
///
/// Note: the PAdES signature creation mechanism is in progress at PSPDFKit, so it is only possible to sign a PDF with PAdES
/// signature using a pre-prepared PAdES signature binary outlined in the steps above.
class EmebedContainedPadesSignatureExample: Example {

    override init() {
        super.init()
        title = "Embed a PAdES advanced digital signature in an already prepared PDF document"
        category = .forms
        priority = 23
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Load a sample document with a signature form field that was already prepared for signing with a PAdES signature.
        // See `PrepareDocumentForContainedPadesSignatureExample` to learn how to do that.
        let document = AssetLoader.writableDocument(for: "PreparedToBePadesSignedDocument.pdf", overrideIfExists: true)
        let newURL = document.fileURL!

        // Now we get the signature form widget.
        let signatureFormElement = document.annotations(at: 0, type: SignatureFormElement.self).first!

        // The prepared signature is a .bin file that contains a PAdES signature using our JohnAppleseed self-signed
        // certificate.
        // See comments above this example class for how we generated this PAdES signature.
        let preparedSignatureSampleURL = AssetLoader.assetURL(for: "PreparedToBePadesSignedSignature.bin")
        // We use the sample `PSPDFSignatureContents` implementation `BinaryFileSignatureContents` from the
        // `ContainedDigitalSignaturesExample.swift` to load our pre-generated PAdES signature binary.
        let signatureContents = BinaryFileSignatureContents(signatureContentsPath: preparedSignatureSampleURL)
        let dataSink = try! FileDataSink(fileURL: newURL, options: [])

        // Finally, create the signer and embed the PAdES signature we have already generated in this document.
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
