//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class MultilineDocumentTitleExample: Example {

    override init() {
        super.init()
        title = "Multiline Document Title"
        contentDescription = "Shows how to configure the document title label to fit a long, multiline title."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        document.title = "This PDF document has a pretty long title. It should wrap into multiple lines on a narrow screen."

        let viewController = PDFViewController(document: document) { builder in
            // If you're expecting long document titles and want to make sure
            // it's always visible, set the following configuration option.
            builder.documentLabelEnabled = .YES
        }

        // Zero means as many lines as needed.
        viewController.userInterfaceView.documentLabel.label.numberOfLines = 0
        viewController.userInterfaceView.documentLabel.label.textAlignment = .center

        return viewController
    }

}
