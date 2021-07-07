//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class CustomSharingFileNamesExample: Example {

    override init() {
        super.init()

        title = "Customize the Sharing Experience"
        contentDescription = "Changes the file name on shared files and adds more sharing options."
        category = .sharing
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .web)
        let sharingConfiguration = DocumentSharingConfiguration.defaultConfiguration(forDestination: .activity).configurationUpdated {
            $0.annotationOptions = [.embed, .flatten, .remove]
            $0.pageSelectionOptions = [.current]
            $0.excludedActivityTypes = [.assignToContact, .postToWeibo, .postToFacebook, .postToTwitter]
        }
        let controller = PDFViewController(document: document, delegate: self) {
            $0.sharingConfigurations = [sharingConfiguration]
        }
        controller.navigationItem.rightBarButtonItems = [controller.activityButtonItem]
        return controller
    }
}

extension CustomSharingFileNamesExample: PDFViewControllerDelegate {
    func pdfViewController(_ pdfController: PDFViewController, didShow controller: UIViewController, options: [String: Any]? = nil, animated: Bool) {
        guard let controller = controller as? PDFDocumentSharingViewController else { return }
        controller.delegate = self
    }
}

extension CustomSharingFileNamesExample: PDFDocumentSharingViewControllerDelegate {
    func documentSharingViewController(_ shareController: PDFDocumentSharingViewController, filenameForGeneratedFileFor sharingDocument: Document, destination: DocumentSharingConfiguration.Destination) -> String? {
        return "NewName"
    }
}
