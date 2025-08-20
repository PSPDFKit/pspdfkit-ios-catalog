//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

class SwiftUISharingExample: Example {

    override init() {
        super.init()

        title = "SwiftUI with Customized Sharing Experience"
        contentDescription = "Set custom delegates for presented view controllers on-the-fly"
        category = .swiftUI
        priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let swiftUIView = SwiftUIExampleView(document: document)
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

/// Standalone delegate handler to customize the title
class DocumentSharingHandler: StandaloneDelegate<PDFDocumentSharingViewControllerDelegate>, PDFDocumentSharingViewControllerDelegate {
    func documentSharingViewController(_ shareController: PDFDocumentSharingViewController, filenameForGeneratedFileFor sharingDocument: Document, destination: DocumentSharingConfiguration.Destination) -> String? {
        "NewName"
    }
}

private struct SwiftUIExampleView: View {
    let document: Document
    @PDFView.Scope private var scope

    var body: some View {
        PDFView(document: document)
            .onDidShowController { controller, _, _ in
                guard let sharingController = controller as? PDFDocumentSharingViewController else { return }
                // The StandaloneDelegateContainer will automatically manage the lifetime of this helper
                // It will be deallocated as soon as sharingController is deallocated.
                // We forward unimplemented callbacks to the default delegate handlers in `PDFViewController`.
                let handler = DocumentSharingHandler(delegateTarget: sharingController,
                                                     originalDelegate: sharingController.delegate)
                // While the handler automatically manages lifetime, Swift 5.5 doesn't know that and creates a warning.
                // The withExtendedLifetime helper prevents this warning.
                withExtendedLifetime(handler) {
                    sharingController.delegate = handler
                }
            }
            .showDocumentTitle()
            .toolbar {
                DefaultToolbarButtons()
            }
            .pdfViewScope(scope)
    }
}
