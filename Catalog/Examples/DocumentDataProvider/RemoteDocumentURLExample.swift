//
//  Copyright © 2020-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// The downloaded document will be read-only.
/// If you want the document to be writable or want more fine-grained control, see `DocumentProgressExample` instead.
class RemoteDocumentURLExample: Example {

    override init() {
        super.init()

        title = "Download and show a PDF from a remote URL"
        contentDescription = "Automatically downloads a PDF with a progress indicator. Optionally caches it for offline storage."
        category = .documentDataProvider
        targetDevice = [.vision, .phone, .pad]
        priority = 1
    }

    let url = URL(string: "https://github.com/PSPDFKit/pspdfkit-ios-catalog/raw/master/Samples/Magazine.pdf")!
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
        // https://www.nutrient.io/blog/downloading-large-files-with-urlsession/
        URLDataProvider.cache = nil

        // Ensure the temporary file does not exist.
        try? FileManager.default.removeItem(at: URLDataProvider.defaultTargetURL(for: url)!)
    }
}
