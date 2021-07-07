//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

class AsynchronousExternalDigitalSignatureExample: Example {

    /// A sample `PDFDocumentSignerDelegate` implementation that asynchronously asks the user for a password to extract
    /// the private key with which the document will be signed.
    class PinEntryDocumentSignerDelegate: NSObject, PDFDocumentSignerDelegate {
        let viewController: UIViewController

        init(with viewController: UIViewController) {
            self.viewController = viewController
        }

        func documentSigner(_ signer: PDFSigner, sign data: Data, hashAlgorithm: PDFSignatureHashAlgorithm, completion: @escaping PSPDFDocumentSignDataCompletionBlock) {
            DispatchQueue.main.async(execute: { () -> Void in
                let alert = UIAlertController(title: "Please enter the .p12 password to sign the document:", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addTextField { textField in
                    textField.placeholder = "Enter the .p12 password here..."
                    textField.isSecureTextEntry = true
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    if let password = alert.textFields?.first?.text {
                        let certURL = AssetLoader.assetURL(for: "JohnAppleseed.p12")
                        let pkcsBlob = try! Data(contentsOf: certURL)
                        let pkcs12 = PKCS12(data: pkcsBlob)
                        pkcs12.unlock(withPassword: password) { _, privateKey, error in
                            // If we can't unlock the .p12 bundle, or we couldn't extract a private key, signal an error.
                            if error != nil {
                                completion(false, nil)
                                return
                            }
                            if privateKey == nil {
                                completion(false, nil)
                                return
                            }
                            let signedData = signer.sign(data, privateKey: privateKey!, hashAlgorithm: hashAlgorithm)
                            completion(true, signedData)
                        }
                    }
                }))
                self.viewController.present(alert, animated: true)
            })
        }
    }

    /// A sample `PinEntryDocumentSignerDataSource` implementation that provides information for the signature:
    /// A particular appearance, and that it should use RSA/SHA512.
    class PinEntryDocumentSignerDataSource: NSObject, PDFDocumentSignerDataSource {
        internal func documentSigner(_ signer: PDFSigner, signatureAppearance formFieldFqn: String) -> PDFSignatureAppearance {
            PDFSignatureAppearance {
                $0.showSignerName = true
                $0.showSignatureReason = true
                $0.appearanceMode = .signatureAndDescription
            }
        }

        internal func documentSigner(_ signer: PDFSigner, signatureHashAlgorithm formFieldFqn: String) -> PDFSignatureHashAlgorithm {
            return .SHA512
        }

        internal func documentSigner(_ signer: PDFSigner, signatureEncryptionAlgorithm formFieldFqn: String) -> PDFSignatureEncryptionAlgorithm {
            return .RSA
        }
    }

    override init() {
        super.init()
        title = "Signs a document asynchronously, simulating a PIN-entry screen."
        contentDescription = "Password is 'test'"
        category = .forms
        priority = 25
    }

    private func generateDestinationFilePath() -> String {
        let destinationFileName = "\(UUID().uuidString).pdf"
        return NSTemporaryDirectory().appending(destinationFileName)
    }

    private func getCertificates(from samplesURL: URL) -> [X509] {
        let certURL = AssetLoader.assetURL(for: "JohnAppleseed.p7c")
        let certData = try? Data(contentsOf: certURL)
        return try! X509.certificates(fromPKCS7Data: certData!)
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        // Load a sample document.
        let unsignedDocument = AssetLoader.writableDocument(for: "Form_example.pdf", overrideIfExists: true)
        let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!
        let destinationFilePath = generateDestinationFilePath()

        // Configure a signer instance.
        let signer = PDFSigner()
        signer.reason = "I agree with the terms of this contract."
        let certificates = getCertificates(from: Bundle.main.resourceURL!.appendingPathComponent("Samples", isDirectory: true))
        let signCertificate = certificates.first!

        // We start the signing process asynchronously and push a view controller with the signed document when we are finished.
        // If the signing process failed, we show an error message instead.
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            // Set a custom delegate and data source for this signer instance.
            let signerDelegate = PinEntryDocumentSignerDelegate(with: delegate.currentViewController!)
            withExtendedLifetime(signerDelegate) {
                signer.delegate = signerDelegate
                let documentSignerDataSource = PinEntryDocumentSignerDataSource()
                withExtendedLifetime(documentSignerDataSource) {
                    signer.dataSource = documentSignerDataSource
                    signer.sign(signatureFormElement, withCertificate: signCertificate,
                                writeTo: destinationFilePath) { success, signedDocument, error -> Void in
                        if success {
                            DispatchQueue.main.async(execute: { () -> Void in
                                delegate.currentViewController?.navigationController?.pushViewController(PDFViewController(document: signedDocument), animated: true)
                            })
                        } else {
                            if let error = error {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    let alert = UIAlertController(title: "Error", message: "The document could not be signed. Error: \(String(describing: error)).", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                                    delegate.currentViewController?.present(alert, animated: true)
                                })
                            }
                        }
                    }
                }
            }
        })

        return nil
    }
}
