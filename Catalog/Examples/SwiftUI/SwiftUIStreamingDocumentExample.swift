//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI
import PSPDFKitUI

/// The streaming document example can download documents on a page-by-page basis,
/// so opening is pretty much instant.
///
/// Please see the header comment of `StreamingDocumentExample` fora list of caveats.
class SwiftUIStreamingDocumentExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Streaming a document on-demand from a web-server"
        contentDescription = "Demonstrates a way to load parts of a document on demand in SwiftUI."
        category = .swiftUI
        priority = 20
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let streamingHelper = StreamingDocumentHelper()
        let fetchableDocument = streamingHelper.fetchableDocument
        let swiftUIView = SwiftUIStreamingDocumentExampleView(fetchableDocument: fetchableDocument)
        let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        streamingHelper.showExampleAlertIfNeeded(on: hostingController)
        return hostingController
    }
}

final class SwiftUIStreamingDocumentExampleViewModel: ObservableObject {
    let fetchableDocument: StreamingDocumentHelper.FetchableDocument
    @Published var document: Document

    // We need the internal wrapped view controller to update individual pages
    weak var controller: PDFViewController?

    init(fetchableDocument: StreamingDocumentHelper.FetchableDocument) {
        self.fetchableDocument = fetchableDocument

        let document = fetchableDocument.buildDocument()
        self.document = document
    }

    func startDownload() {
        fetchableDocument.downloadAllFiles { chunkIndex, fileURL in
            // As files are downloaded, we swap the data-based document provider with a file-based one.
            self.document.reload(documentProviders: [self.document.documentProviders[chunkIndex]]) { _ in
                FileDataProvider(fileURL: fileURL)
            }
            // We also need to reload the UI to re-render the current page.
            // Operations touching UIKit must be done on the main thread.
            let range = self.fetchableDocument.pagesFor(chunkIndex: chunkIndex)
            DispatchQueue.main.async {
                self.controller?.reloadPages(indexes: IndexSet(range), animated: true)
            }
        }
    }
}

private struct SwiftUIStreamingDocumentExampleView: View {
    @ObservedObject var viewModel: SwiftUIStreamingDocumentExampleViewModel

    init(fetchableDocument: StreamingDocumentHelper.FetchableDocument) {
        viewModel = SwiftUIStreamingDocumentExampleViewModel(fetchableDocument: fetchableDocument)
    }

    var body: some View {
        return VStack {
            PDFView(document: viewModel.document)
                .pageMode(.single)
                .pageLabelEnabled(false)
                .thumbnailBarMode(.scrollable)
                .updateConfiguration(builder: { builder in
                    builder.overrideClass(PDFPageView.self, with: ProgressPageView.self)
                })
                .spreadFitting(.fill)
                .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                .updateControllerConfiguration { controller in
                    viewModel.controller = controller
                    if #available(iOS 14.0, *) {
                        let clearCacheItem = UIBarButtonItem(title: "Clear Cache", image: nil, primaryAction: UIAction(title: "", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak controller] _ in

                            try? FileManager.default.removeItem(at: viewModel.fetchableDocument.downloadFolder)
                            let document = viewModel.fetchableDocument.buildDocument()
                            controller?.document = document
                            viewModel.document = document
                            viewModel.startDownload()

                        }), menu: nil)
                        let exitItem = UIBarButtonItem(title: "Exit", image: nil, primaryAction: UIAction(title: "", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak controller] _ in
                            controller?.navigationController?.popViewController(animated: true)
                        }), menu: nil)

                        controller.navigationItem.setLeftBarButtonItems([exitItem, clearCacheItem], for: .document, animated: false)
                        controller.navigationItem.leftItemsSupplementBackButton = false
                    }
                }.onAppear {
                    viewModel.startDownload()
                }
        }
        // Prevent jumping of the content as we show/hide the navigation bar
        .edgesIgnoringSafeArea(.all)
    }
}
