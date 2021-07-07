//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit

class RemoteDocumentURLExample: Example {

    override init() {
        super.init()

        title = "Download and show a PDF from a remote URL"
        contentDescription = "Automatically downloads and caches a PDF with progress indicator and offline storage."
        category = .miscellaneous
        priority = 2
    }

    let url = URL(string: "https://www.adobe.com/content/dam/acom/en/devnet/pdf/pdf_reference_archive/pdf_reference_1-7.pdf")!
    let alwaysDownloadFile = true

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        clearCacheIfNecessary()

        let document = Document(url: url)
        let controller = PDFViewController(document: document)
        return controller
    }

    private func clearCacheIfNecessary() {
        guard alwaysDownloadFile else { return }

        // Downloads by default use this custom, large cache to ensure files are being updated correctly.
        // Set the cache to nil to disable this caching.
        // https://pspdfkit.com/blog/2020/downloading-large-files-with-urlsession/
        URLDataProvider.cache = nil

        // Ensure the temporary file does not exist.
        try? FileManager.default.removeItem(at: URLDataProvider.defaultTargetURL(for: url)!)
    }
}
