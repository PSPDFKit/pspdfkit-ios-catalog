//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class EncryptedCacheExample: Example {

    override init() {
        super.init()
        title = "Enable PDFCache encryption"
        contentDescription = "Wrap cache access into an encryption layer."
        category = .security
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let cache = SDK.shared.cache
        // Clear existing cache
        cache.clear()

        // Set new cache directory so this example doesn't interfere with the other examples
        cache.diskCache.cacheDirectory = "PSPDFKit_encrypted"

        // In a real use case, you want to protect the password better than hard-coding it here.
        let password: String = "unsafe-testpassword"

        // Set up cache encryption handlers.
        // Encrypting the images will be a 5-10% slowdown, nothing substantial.
        cache.diskCache.encryptionHelper = {(_ request: RenderRequest, _ data: Data) -> Data in
            return RNCryptor.encrypt(data: data, withPassword: password)
        }

        cache.diskCache.decryptionHelper = {(_ request: RenderRequest, _ encryptedData: Data) -> Data? in
            do {
                return try RNCryptor.decrypt(data: encryptedData, withPassword: password)
            } catch {
                print("Failed to decrypt: \(error.localizedDescription)")
                return nil
            }
        }

        // Open sample document
        let document = AssetLoader.document(for: .JKHF)
        return PDFViewController(document: document)
    }
}
