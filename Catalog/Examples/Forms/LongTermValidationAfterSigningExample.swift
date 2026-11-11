//
//  Copyright © 2023-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

@MainActor class LongTermValidationAfterSigningExample: Example {
    override init() {
        super.init()

        title = "Add Long Term Validation (LTV) After Signing"
        contentDescription = "How to add LTV to an existing digital signature."
        category = .forms
        priority = 25
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let unsignedDocument = AssetLoader.document(for: "Form.pdf")
        let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!

        let signedDocumentURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("\(UUID().uuidString).pdf"))

        let navigationController = delegate.currentViewController!.navigationController!
        do {
            let pkcs8FileURL = AssetLoader.assetURL(for: "SimpleSigner.key")
            let pkcs8Data = try Data(contentsOf: pkcs8FileURL)
            guard let privateKey = PrivateKey.create(fromRawPrivateKey: pkcs8Data, encoding: .PKCS8) else {
                navigationController.showAlert(withTitle: "Error creating PKCS#8 private key.")
                print("Error creating PKCS#8 private key.")
                return nil
            }

            let signingCertificates = try X509.certificates(fromPKCS7Data: Data(contentsOf: AssetLoader.assetURL(for: "SimpleSigner.cert")))

            let caCertificates = try X509.certificates(fromPKCS7Data: Data(contentsOf: AssetLoader.assetURL(for: "ca_root.cert")))

            // In the example we do this here, but in your app you can set this early
            // in the app lifecycle and don't need to clear them.
            let signatureManager = SDK.shared.signatureManager
            signatureManager.clearTrustedCertificates()
            for cert in caCertificates {
                signatureManager.addTrustedCertificate(cert)
            }

            Task {
                do {
                    let configuration = SigningConfiguration(dataSigner: privateKey, certificates: signingCertificates, isLongTermValidationEnabled: false)
                    try await unsignedDocument.sign(formElement: signatureFormElement, configuration: configuration, outputDataProvider: FileDataProvider(fileURL: signedDocumentURL))
                    let signedDocument = Document(url: signedDocumentURL)

                    let pdfController = PDFViewController(document: signedDocument)
                    let addLTVButton = UIBarButtonItem(title: "Add LTV", primaryAction: UIAction { _ in
                        Task {
                            do {
                                guard let signedSignatureFormElement = signedDocument.annotations(at: 0, type: SignatureFormElement.self).first else {
                                    navigationController.showAlert(withTitle: "Signature field to add LTV to couldn't be found")
                                    return
                                }

                                let signingCertificates = try X509.certificates(fromPKCS7Data: Data(contentsOf: AssetLoader.assetURL(for: "SimpleSigner.cert")))

                                try await signedDocument.addLongTermValidation(toFormElement: signedSignatureFormElement, certificates: signingCertificates)
                                navigationController.showAlert(withTitle: "LTV added to signature")
                            } catch {
                                navigationController.showAlert(withTitle: "Adding LTV failed", message: "\(error)")
                            }
                        }
                    })
                    pdfController.navigationItem.setRightBarButtonItems([pdfController.annotationButtonItem, addLTVButton], for: .document, animated: true)
                    navigationController.pushViewController(pdfController, animated: true)
                } catch {
                    navigationController.showAlert(withTitle: "Couldn't add signature", message: "\(error)")
                    print(error)
                }
            }
        } catch {
            navigationController.showAlert(withTitle: "Failed to get certificates", message: "\(error)")
            return nil
        }

        return nil
    }
}
