//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCAESCryptoDataProviderExample.m' for the Objective-C version of this example.

import Foundation

class AESCryptoDataProviderExample: Example {

    override init() {
        super.init()
        title = "PSPDFAESCryptoDataProvider"
        contentDescription = "Example how to decrypt a AES256 encrypted PDF on the fly."
        category = .security
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let encryptedPDF = AssetLoader.assetURL(for: "aes-encrypted.pdf.aes")

        // Note: For shipping apps, you need to protect this string better, making it harder for hacker to simply disassemble and receive the key from the binary. Or add an internet service that fetches the key from an SSL-API. But then there's still the slight risk of memory dumping with an attached gdb. Or screenshots. Security is never 100% perfect; but using AES makes it way harder to get the PDF. You can even combine AES and a PDF password.
        let passphrase = "afghadöghdgdhfgöhapvuenröaoeruhföaeiruaerub"
        let salt = "ducrXn9WaRdpaBfMjDTJVjUf3FApA6gtim0e61LeSGWV9sTxB0r26mPs59Lbcexn"

        // PSPDFKit doesn't want to keep the passphrase in memory any longer than it has to. This is the reason we use a passphrase provider.
        // For optimal results, always fetch the passphrase from secure storage (like the keychain) and never keep it in memory.
        let passphraseProvider = { passphrase }

        guard let cryptoWrapper = AESCryptoDataProvider(url: encryptedPDF, passphraseProvider: passphraseProvider, salt: salt, rounds: AESCryptoDataProvider.defaultNumberOfPBKDFRounds) else {
            return PDFViewController(document: nil)
        }

        let document = Document(dataProviders: [cryptoWrapper])
        document.uid = encryptedPDF.lastPathComponent // Manually set a UID for encrypted documents.

        // `PSPDFAESCryptoDataProvider` automatically disables `useDiskCache` to restrict using the disk cache for encrypted documents.
        // If you use a custom crypto solution, don't forget to disable `useDiskCache` on your custom data provider or on the document,
        // in order to avoid leaking out encrypted data as cached images.
//        document.useDiskCache = false

        return PDFViewController(document: document)
    }
}
