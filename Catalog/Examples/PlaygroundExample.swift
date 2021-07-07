//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCPlaygroundExample.m' for the Objective-C version of this example.

class PlaygroundExample: Example {

    override init() {
        super.init()

        title = "PDFViewController Playground"
        contentDescription = "Start here"
        type = "com.pspdfkit.catalog.playground.swift"
        category = .top
        priority = 1
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Playground is convenient for testing
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        let controller = AdaptivePDFViewController(document: document) {
            // Use the configuration to set main PSPDFKit options.
            $0.signatureStore = KeychainSignatureStore()
        }
        return controller
    }
}
