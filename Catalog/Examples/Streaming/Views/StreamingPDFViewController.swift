//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// Subclass to forward apperarance events to the streaming document (for smart downloading)
final class StreamingPDFViewController: PDFViewController, PDFViewControllerDelegate {

    /// Internal download tracker.
    var thumbnailDownloads: [URL: URLSessionTask] = [:]

    private var observer: Any?

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)
        StreamingDownloadCoordinator.shared.activeStreamingDefinition = streamingDefinition

        delegate = self

        observer = NotificationCenter.default.addObserver(forName: .StreamingDownloadCoordinatorDidDownloadFile, object: StreamingDownloadCoordinator.shared, queue: nil) { [weak self] notification in
            guard let userInfo = notification.userInfo else { return }
            let chunkIndex = userInfo["chunkIndex"] as! Int
            let fileURL = userInfo["targetURL"] as! URL
            self?.reload(chunkIndex: chunkIndex, fileURL: fileURL)
        }
    }

    override func reloadData() {
        // Connect document with controller for image loader.
        streamingDocument?.streamingController = self
        super.reloadData()
    }

    /// Convenience accessor to the streaming document.
    var streamingDocument: StreamingDocument? {
        document as? StreamingDocument
    }

    var streamingDefinition: StreamingDocumentDefinition? {
        streamingDocument?.streamingDefinition
    }

    func renderAnnotations(at pageIndex: PageIndex, image: UIImage) -> UIImage {
        guard let document = streamingDocument,
              case let annotations = document.userProvidedAnnotations(pages: Int(pageIndex) ..< Int(pageIndex) + 1), !annotations.isEmpty
        else { return image }

        let renderer = UIGraphicsImageRenderer(size: image.size, format: image.imageRendererFormat)
        let newImage = renderer.image { ctx in
            image.draw(at: CGPoint(x: 0, y: 0))

            let renderOptions = RenderOptions()
            renderOptions.skipPageContent = true
            try? document.renderPage(at: pageIndex, context: ctx.cgContext, size: image.size, clippedTo: .zero, annotations: annotations, options: renderOptions)
        }

        return newImage
    }

    /// Fetches a thumbnail image.
    func downloadThumbnail(at pageIndex: PageIndex, completionHandler: @escaping (Result<UIImage, Error>) -> Void) {
        precondition(Thread.isMainThread)

        guard let streamingDefinition = self.streamingDefinition else { return }

        let url = streamingDefinition.thumbnailURL(for: pageIndex)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.thumbnailDownloads[url] = nil
            }

            guard error == nil else { completionHandler(.failure(error!)); return }

            // Make sure image response is correct, bail otherwise with custom error
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data, error == nil,
                let image = UIImage(data: data, scale: self.traitCollection.displayScale)
            else {
                // Create a custom error to satisfy API contract
                let error = NSError(domain: PSPDFErrorDomain, code: PSPDFKitError.fileNotFound.rawValue, userInfo: nil)
                completionHandler(.failure(error))
                return
            }
            // We got the image, call completion handler.
            // If there are user annotations, we want to render them into the thumbnail
            let imageWithAnnotations = self.renderAnnotations(at: pageIndex, image: image)
            completionHandler(.success(imageWithAnnotations))
        }
        // Thumbnails should be prioritized over page downloads.
        task.priority = URLSessionTask.highPriority
        thumbnailDownloads[url] = task
        task.resume()
    }

    func downloadFile(pageIndex: PageIndex) {
        StreamingDownloadCoordinator.shared.downloadFile(pageIndex: pageIndex)
    }

    private func reload(chunkIndex: Int, fileURL: URL) {
        guard let document = self.document,
              let streamingDefinition = self.streamingDefinition else { return }

        if chunkIndex >= document.documentProviders.count {
            preconditionFailure()
        }
        // As files are downloaded, we swap the data-based document provider with a file-based one.
        document.reload(documentProviders: [document.documentProviders[chunkIndex]]) { _ in
            FileDataProvider(fileURL: fileURL)
        }
        // We also need to reload the UI to re-render the current page.
        // Operations touching UIKit must be done on the main thread.
        let range = streamingDefinition.pagesFor(chunkIndex: chunkIndex)
        DispatchQueue.main.async {
            self.reloadPages(indexes: IndexSet(range), animated: true)
        }
    }

    // Strategy to download files:
    // Always start requesting the PDF if a page is displayed.
    // If we already download a PDF, do not download thumbnail
    // Else, download requested thumbnail.
    // If there are no more downloads, fetch single PDF pages until we're done.

    /// Stops downloading document files.
    func stopDownloadingFiles() {
        thumbnailDownloads.values.forEach { $0.cancel() }
        thumbnailDownloads.removeAll()

        StreamingDownloadCoordinator.shared.cancelAll()
    }

    // MARK: - PDFViewControllerDelegate

    func pdfViewControllerWillDismiss(_ pdfController: PDFViewController) {
        stopDownloadingFiles()
    }
}
