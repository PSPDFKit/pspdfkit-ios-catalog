//
//  Copyright © 2019-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class DisableRemovingDigitalSignatureExample: Example {

    override init() {
        super.init()
        title = "Disable removing Digital Signature"
        category = .forms
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: "Signed Form.pdf", overrideIfExists: false)
        return PDFViewController(document: document) {
            // Set `allowDeletingDigitalSignatures` to false to disable removing of added Digital Signatures.
            $0.allowRemovingDigitalSignatures = false
        }
    }

}
