//
//  Copyright © 2018-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

@MainActor class AsynchronousExternalDigitalSignatureExample: Example {

    override init() {
        super.init()
        title = "Signs a document asynchronously, simulating a PIN-entry screen."
        contentDescription = "Password is 'test'"
        category = .forms
        priority = 25
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        Task {
            let presentingController = delegate.currentViewController!.navigationController!

            // Present the alert asking for the password for the digital certificate.
            guard let enteredPin = await presentPinEntryAlert(on: presentingController) else { return }

            resetAndAddCertificatesToTrustStore()

            do {
                // Unlock the certificate chain for signing.
                let (certificates, privateKey) = try unlockCertificateChain(withPassword: enteredPin)

                // Create the destination URL for the signed document.
                let fileName = "\(UUID().uuidString).pdf"
                let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))

                // Access the unsigned document and signature form element.
                let unsignedDocument = AssetLoader.document(for: "Form.pdf")
                let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!

                let signatureAppearance = PDFSignatureAppearance {
                    $0.showSignerName = true
                    $0.showSignatureReason = true
                    $0.appearanceMode = .signatureAndDescription
                }
                let configuration = SigningConfiguration(dataSigner: privateKey, certificates: certificates, hashAlgorithm: .SHA512, appearance: signatureAppearance, reason: "I agree with the terms of the contract.")
                try await unsignedDocument.sign(formElement: signatureFormElement, configuration: configuration, outputDataProvider: FileDataProvider(fileURL: url))
                presentingController.pushViewController(PDFViewController(document: Document(url: url)), animated: true)
            } catch {
                presentingController.showAlert(withTitle: "Couldn't add signature", message: "\(error)")
                print(error)
            }

        }

        return nil
    }

    /// Retrieves the unlocked key and certifcates from the "John Appleseed" private key using the given password.
    private func unlockCertificateChain(withPassword password: String) throws -> ([X509], PrivateKey) {
        let p12URL = AssetLoader.assetURL(for: "John Appleseed Private Key.p12")
        let pkcsBlob = try! Data(contentsOf: p12URL)
        let pkcs12 = PKCS12(data: pkcsBlob)
        return try pkcs12.unlockCertificateChain(withPassword: password)
    }

    /// Presents an alert controller asking for the password to unlock the private key of the "John Appleseed" signing certificate.
    /// - Returns: Entered password string.
    private func presentPinEntryAlert(on viewController: UIViewController) async -> String? {
        let alert = UIAlertController(title: "Please enter the .p12 password to sign the document:", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter the .p12 password here..."
            textField.isSecureTextEntry = true
        }

        return await withCheckedContinuation { continuation in
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                continuation.resume(returning: nil)
            }))

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                let password = alert.textFields?.first?.text
                continuation.resume(returning: password)
            }))
            viewController.present(alert, animated: true)
        }
    }

    /// Adds the demo "John Appleseed" public key to trusted certificate store of the `PDFSignatureManager` in Nutrient after reseting the store.
    private func resetAndAddCertificatesToTrustStore() {
        // Reset the trusted certificates.
        let signatureManager = SDK.shared.signatureManager
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certURL = AssetLoader.assetURL(for: "John Appleseed Public Key.p7c")
        let certData = try? Data(contentsOf: certURL)
        let certificates = try? X509.certificates(fromPKCS7Data: certData!)
        for x509 in certificates! {
            signatureManager.addTrustedCertificate(x509)
        }
    }
}
