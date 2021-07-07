//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

class ScrubberBarWithButtonsExample: Example {
    override init() {
        super.init()
            title = "Scrubber Bar with buttons"
            contentDescription = "Adds UIBarButtonItems to the scrubber bar"
            category = .viewCustomization
            priority = 401
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        let pdfController = PDFViewController(document: document)

        // Add buttons to the scrubber toolbar
        let leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(leftButtonPressed(_:)))
        let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(rightButtonPressed(_:)))
        let spacingItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        pdfController.userInterfaceView.scrubberBar.toolbar.items = [leftBarButtonItem, spacingItem, rightBarButtonItem]

        // Set the margin
        let margin: CGFloat = 50.0
        pdfController.userInterfaceView.scrubberBar.leftBorderMargin = margin
        pdfController.userInterfaceView.scrubberBar.rightBorderMargin = margin

        return pdfController
    }

    @objc func leftButtonPressed(_ sender: Any?) {
        print("Left button pressed.")
    }

    @objc func rightButtonPressed(_ sender: Any?) {
        print("Right button pressed.")
    }
}
