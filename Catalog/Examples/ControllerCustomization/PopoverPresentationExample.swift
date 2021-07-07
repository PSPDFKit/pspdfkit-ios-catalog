//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCPopoverPresentationExample.m' for the Objective-C version of this example.

class PopoverPresentationExample: Example {

    override init() {
        super.init()

        title = "PDFViewController in Popover"
        contentDescription = "Uses a vanilla PDFViewController presented in a popover presentation controller."
        category = .controllerCustomization
        wantsModalPresentation = true
        customizations = { container in
            container.modalPresentationStyle = .popover
            container.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        let controller = PDFViewController(document: document)
        controller.preferredContentSize = CGSize(width: 640, height: 480)
        return controller
    }
}
