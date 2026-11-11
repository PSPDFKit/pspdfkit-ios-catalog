//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class PredefinedEmailBodyExample: Example {

    override init() {
        super.init()
        title = "Custom Email Message Body"
        contentDescription = "Shows how to set a predefined message body when sending an email."
        category = .sharing
        priority = 900
        if MFMailComposeViewController.canSendMail() == false {
            targetDevice = []
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)
        let pdfController = PDFViewController(document: document) {
            $0.overrideClass(PDFDocumentSharingViewController.self, with: SharingViewController.self)
        }
        pdfController.navigationItem.rightBarButtonItems = [pdfController.emailButtonItem]
        return pdfController
    }
}

private class SharingViewController: PDFDocumentSharingViewController {
    override func configureMailComposeViewController(_ mailComposeViewController: MFMailComposeViewController?) {
        mailComposeViewController?.setMessageBody("<h1 style='color:blue'>Custom message body.</h1>", isHTML: true)
    }
}
