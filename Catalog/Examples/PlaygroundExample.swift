//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCObjectiveCExample.m' for the Objective-C version of this example.

import PSPDFKit
import PSPDFKitUI

class PlaygroundExample: Example {

    override init() {
        super.init()

        title = "Playground"
        contentDescription = "Start here!"
        category = .top
        targetDevice = [.vision, .phone, .pad]
        priority = 1
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Playground is convenient for testing
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        let controller = AdaptivePDFViewController(document: document) {
            // Use the configuration to set main options for the Nutrient UI.
            $0.signatureStore = KeychainSignatureStore()
        }

        return controller
    }
}
