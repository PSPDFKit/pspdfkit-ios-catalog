//
//  Copyright © 2017-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class PasswordNotPresetExample: Example {

    override init() {
        super.init()
        title = "Password not preset"
        contentDescription = "Dialog will be shown. Password is 'test123'"
        category = .security
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Password-Protected.pdf")
        return PDFViewController(document: document)
    }
}
