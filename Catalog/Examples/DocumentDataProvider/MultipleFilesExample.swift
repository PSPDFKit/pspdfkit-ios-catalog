//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class MultipleFilesExample: Example {
    override init() {
        super.init()
        title = "Using Multiple Files"
        contentDescription = "Display a single document backed by multiple PDF data providers."
        category = .documentDataProvider
        priority = 40
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let fileNames = ["A.pdf", "B.pdf", "C.pdf", "D.pdf"]

        // Collection of multiple data providers that will be used to display a combined single document.
        // See https://pspdfkit.com/guides/ios/features/data-providers to learn more about Data Providers.
        let dataProviders = fileNames.map { fileName -> DataProviding in
            let fileURL = AssetLoader.assetURL(for: AssetName(rawValue: fileName))
            // Copy the files to a writable location so that the data providers can write to the backing
            // file if needed.
            let writableURL = fileURL.copyToDocumentDirectory()

            // `FileDataProvider` can be used to read and write to the backing file at the URL.
            // However that doesn't use file coordination. See use of `CoordinatedFileDataProvider` below.
            // return FileDataProvider(fileURL: writableURL)

            // PSPDFKit also allows you to load PDF from a Data object.
            // Changes to the PDF document using this data provider will not be written to the disk.
            // Data mapped to the memory (virtual) can also be used.
            // let dataContents = try! Data(contentsOf: writableURL, options: .mappedIfSafe)
            // return DataContainerProvider(data: dataContents)

            // See AESCryptoDataProviderExample.swift if you wish to use encrypted data provider.

            // We are using a `CoordinatedFileDataProvider` which is similar to `FileDataProvider`
            // but also uses file coordination.
            // See https://pspdfkit.com/guides/ios/features/file-coordination/ for more info on File Coordination.
            return CoordinatedFileDataProvider(fileURL: writableURL)
        }

        // Use the above created data providers to create and load a document.
        let document = Document(dataProviders: dataProviders)
        document.title = "Using Multiple Files Example"

        // Display the document backed by multiple PDF data providers.
        let controller = PDFViewController(document: document)

        return controller
    }
}
