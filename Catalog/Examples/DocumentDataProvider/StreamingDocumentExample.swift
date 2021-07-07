//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

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
/// - Undo/Redo is not supported.
/// - The replaced document must have the same page count as the template part
/// - Only documents with a uniform page size are supported correctly. The document size is defined by the first page.
final class StreamingDocumentExample: Example {
    override init() {
        super.init()
        title = "Streaming a document on-demand from a web-server"
        self.contentDescription = "Demonstrates a way to load parts of a document on demand."
        category = .documentDataProvider
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let streamingHelper = StreamingDocumentHelper()
        let fetchableDocument = streamingHelper.fetchableDocument
        let document = fetchableDocument.buildDocument()

        let controller = PDFViewController(document: document) {
            $0.pageMode = .single
            // page labels will be confusing for split documents
            $0.isPageLabelEnabled = false
            $0.thumbnailBarMode = .scrollable
            // Use custom page view that shows download progress
            $0.overrideClass(PDFPageView.self, with: ProgressPageView.self)
        }

        let startDownload = {
            fetchableDocument.downloadAllFiles { chunkIndex, fileURL in
                guard let document = controller.document else { return }

                // As files are downloaded, we swap the data-based document provider with a file-based one.
                document.reload(documentProviders: [document.documentProviders[chunkIndex]]) { _ in
                    FileDataProvider(fileURL: fileURL)
                }
                // We also need to reload the UI to re-render the current page.
                // Operations touching UIKit must be done on the main thread.
                let pages = fetchableDocument.pagesFor(chunkIndex: chunkIndex)
                DispatchQueue.main.async {
                    controller.reloadPages(indexes: NSIndexSet(indexSet: IndexSet(pages)) as IndexSet, animated: true)
                }
            }
        }

        // Add menu on iOS 14 and newer (Example works on iOS 12 as well, just not advanced testing helpers)
        if #available(iOS 14.0, *) {
            let clearCacheItem = UIBarButtonItem(title: "Clear Cache", image: nil, primaryAction: UIAction(title: "", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak controller] _ in

                try? FileManager.default.removeItem(at: fetchableDocument.downloadFolder)
                controller?.document = fetchableDocument.buildDocument()
                startDownload()

            }), menu: nil)
            controller.navigationItem.setLeftBarButtonItems([clearCacheItem], for: .document, animated: false)
            controller.navigationItem.leftItemsSupplementBackButton = true
        }

        startDownload()

        // Show explain alert if there is no webserver running.
        streamingHelper.showExampleAlertIfNeeded(on: controller)

        return controller
    }
}

/// A page view subclass that can show a progress indicator centered to the page.
final class ProgressPageView: PDFPageView {
    /// Enable or disable displaying the progress view. Animates.
    var showProgressIndicator: Bool = false {
        didSet {
            guard showProgressIndicator != oldValue else { return }
            UIView.animate(withDuration: 0.3) {
                self.progressView.alpha = self.showProgressIndicator ? 1: 0
            }
        }
    }

    // Create and setup lazily
    lazy var progressView: UIActivityIndicatorView = {
        let progressView = UIActivityIndicatorView(style: .large)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        annotationContainerView.addSubview(progressView)
        progressView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        progressView.startAnimating()
        return progressView
    }()

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateProgressIndicator()
    }

    override func update() {
        super.update()
        updateProgressIndicator()
    }

    private func updateProgressIndicator() {
        // If the page is not backed by a file, it's still being loaded
        let documentProvider = presentationContext?.document?.documentProviderForPage(at: pageIndex)
        showProgressIndicator = documentProvider?.fileURL == nil
    }
}
