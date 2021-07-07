//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class InsetUserInterfaceExample: Example {
    override init() {
        super.init()
        title = "Inset User Interface"
        contentDescription = "Make space for custom UI elements"
        category = .viewCustomization
        priority = 410
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        let pdfController = InsetUserInteracePDFViewController(document: document)
        return pdfController
    }
}

private class InsetUserInteracePDFViewController: PDFViewController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Inset value of how much the scrubber bar should be moved up.
        let bottomInset: CGFloat = 100

        // Change the frame of the user interface view by moving it up
        // the amount of bottomInset.
        var userInterfaceFrame = self.view.bounds
        userInterfaceFrame.size.height -= bottomInset
        userInterfaceView.frame = userInterfaceFrame
    }
}
