//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class EncryptDecryptDocumentExample: Example {
	override init() {
        super.init()
        title = "Encrypt and decrypt a PDF"
        contentDescription = "Example how to encrypt and decrypt PDF."
        category = .security
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let originalURL = AssetLoader.assetURL(for: .annualReport)
        let cryptor = Cryptor()
        let key = cryptor.key(fromPassphrase: "passphrase", salt: "salt")

        // Encrypt the original PDF
        let encryptedURL = FileHelper.temporaryPDFFileURL(prefix: "encrypted")
        do {
            try cryptor.encrypt(from: originalURL, to: encryptedURL, key: key)
        } catch {
            print("Encryption failed with error: \(error.localizedDescription)")
        }

        // Decrypt the encrypted PDF
        let decryptedURL = FileHelper.temporaryPDFFileURL(prefix: "PSPDFCryptorTests")
        do {
            try cryptor.decrypt(from: encryptedURL, to: decryptedURL, key: key)
        } catch {
            print("Decrypton failed with error: \(error.localizedDescription)")
        }
        // Open the decrypted PDF
        let document = Document(url: decryptedURL)
        return PDFViewController(document: document)
    }
}
