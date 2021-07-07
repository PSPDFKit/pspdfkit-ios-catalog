//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCPasswordPresetExample.m' for the Objective-C version of this example.

import Foundation

class PasswordPresetExample: Example {

    override init() {
        super.init()
        title = "Password preset"
        category = .security
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: AssetName(rawValue: "protected.pdf"))
        document.unlock(withPassword: "test123")
        return PDFViewController(document: document)
    }
}
