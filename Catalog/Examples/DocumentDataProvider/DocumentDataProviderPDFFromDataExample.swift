//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DocumentDataProviderPDFFromDataExample: Example {
    override init() {
        super.init()
        title = "Initializing with Data"
        contentDescription = "Initialize a PDF document with Data contents."
        category = .documentDataProvider
        priority = 20
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let assetURL = AssetLoader.assetURL(for: .quickStart)

        guard let data = try? Data(contentsOf: assetURL, options: .mappedIfSafe) else {
            print("Unable to access contents of \(assetURL.path)")
            return nil
        }

        // Create `DataContainerProvider` using the Data at the URL.
        // See https://pspdfkit.com/guides/ios/features/data-providers/ for more details.
        let dataContainerProvider = DataContainerProvider(data: data)

        // Use the above created data provider to create and load a document.
        // This will be only an in-memory document. The changes made to the document will not be
        // saved to disk. If you wish to be able to persist the changes to the original asset URL
        // then please consider using the `FileDataProvider` instead.
        // Also, see MultipleFilesExample.swift.
        let document = Document(dataProviders: [dataContainerProvider])

        // Display the document loaded using the contents at the URL.
        let controller = PDFViewController(document: document)
        controller.navigationItem.setRightBarButtonItems([controller.thumbnailsButtonItem, controller.outlineButtonItem, controller.searchButtonItem, controller.activityButtonItem], for: .document, animated: false)

        return controller
    }
}
