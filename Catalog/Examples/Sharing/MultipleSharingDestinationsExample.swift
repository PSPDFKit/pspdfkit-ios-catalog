//
//  Copyright © 2023-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class MultipleSharingDestinationsExample: Example {

    override init() {
        super.init()

        title = "Show Multiple Destinations for Sharing"
        contentDescription = "Shows how to configure multiple destinations for sharing a document."
        category = .sharing
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        let controller = AdaptivePDFViewController(document: document) {
            $0.signatureStore = KeychainSignatureStore()
            $0.sharingConfigurations = [
                DocumentSharingConfiguration {
                    $0.pageDescriptionProvider = { pageIndex, _ in
                        NumberFormatter.localizedString(from: pageIndex + 1 as NSNumber, number: .spellOut)
                    }
                    $0.selectedPagesDescriptionProvider = { selectedPages in
                        switch selectedPages {
                        case .current:
                            return "Custom Text for current page"
                        case .range(let selectedPageIndexes, _):
                            return "Custom Text for range: \(NumberFormatter.localizedString(from: selectedPageIndexes.first! + 1 as NSNumber, number: .spellOut)) - \(NumberFormatter.localizedString(from: selectedPageIndexes.last! + 1 as NSNumber, number: .spellOut))"
                        case .all:
                            return "Custom Text for All Pages"
                        case .annotated:
                            return "Custom text for annotated pages"
                        }
                    }
                    $0.destination = .activity
                },
                ProcessInfo.processInfo.isMacCatalystApp ? nil : DocumentSharingConfiguration {
                    $0.destination = .otherApplication
                    $0.annotationOptions = [.embed]
                },
                MFMailComposeViewController.canSendMail() ? DocumentSharingConfiguration {
                    $0.destination = .email
                    $0.annotationOptions = [.remove, .summary]
                    $0.fileFormatOptions = [.PDF]
                } : nil,
                DocumentSharingConfiguration {
                    $0.destination = .export

                },
                MFMessageComposeViewController.canSendAttachments() ? DocumentSharingConfiguration {
                    $0.destination = .messages
                    $0.pageSelectionOptions = .annotated
                } : nil,
            ].compactMap(\.self)
        }
        return controller
    }
}
