//
//  Copyright © 2020-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// The streaming document example can download documents on a page-by-page basis,
/// so opening is pretty much instant.
///
/// This can be useful if you have a large document that you'd like to stream to the user in individual pages.
/// It requires that the document is split up into individual pages and accessible on your web server.
///
/// To test: Open a local webserver in the folder where the document can be found.
/// A simple way is via python, which is installed by default on macOS:
///
/// - python -m SimpleHTTPServer 8000    # Python 2
/// - python -m http.server              # Python 3
///
/// This example is a special case for fast display and comes with a few caveats:
/// - The document needs to be separated on a server
/// - Document outlines are not supported
/// - Document page labels are not supported
/// - Document Editor is not supported
/// - Digital Signatures are not supported
/// - The replaced document must have the same page count as the template part
/// - Only documents with a uniform page size are supported correctly. The document size is defined by the first page.
final class StreamingDocumentExample: Example {
    override init() {
        super.init()
        title = "Streaming a document on-demand from a web-server"
        self.contentDescription = "Demonstrates a way to load parts of a document on demand."
        category = .documentDataProvider
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let streamingHelper = StreamingDocumentGenerator()
        let document = streamingHelper.streamingDocument

        let controller = StreamingPDFViewController(document: document) {
            $0.pageMode = .single
            // page labels will be confusing for split documents
            $0.isPageLabelEnabled = false
            $0.thumbnailBarMode = .scrollable
            // Use custom page view that shows download progress
            $0.overrideClass(PDFPageView.self, with: StreamingPageView.self)

            // These are optional, only if you need streaming thumbnails.
            $0.overrideClass(ThumbnailBar.self, with: StreamingThumbnailBar.self)
            $0.overrideClass(ThumbnailViewController.self, with: StreamingThumbnailViewController.self)
        }

        let clearCacheItem = UIBarButtonItem(title: "Clear Cache", image: nil, primaryAction: UIAction(title: "", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak controller] _ in

            controller?.stopDownloadingFiles()

            SDK.shared.cache.clear()
            try? FileManager.default.removeItem(at: document.streamingDefinition.downloadFolder)
            let newDocument = StreamingDocument(streamingDefinition: document.streamingDefinition)
            controller?.document = newDocument
            controller?.downloadFile(pageIndex: 0)

        }), menu: nil)
        controller.navigationItem.setLeftBarButtonItems([clearCacheItem], for: .document, animated: false)
        controller.navigationItem.leftItemsSupplementBackButton = true

        // Show explain alert if there is no webserver running.
        streamingHelper.showExampleAlertIfNeeded(on: controller)

        return controller
    }
}
