//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import AVFoundation
import PSPDFKit
import PSPDFKitUI

/// This helper is used in combination with the streaming example, to split the page
/// and explain how a local server should be started in order to run the example.
///
/// In your app, you do not need all of this logic, as the document should be hosted on a server, not on your local Mac.
struct StreamingDocumentGenerator {
    let streamingDocument: StreamingDocument
    private let terminalCode: String
    private var observer: Any?

    @MainActor init() {
        let pagesPerChunk = 2

        // Clear cache + load document and split into a temporary folder
        SDK.shared.cache.clear()
        let documentURL = AssetLoader.document(for: .welcome).fileURL!
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        try? StreamingDocumentGenerator.splitDocument(fileURL: documentURL, outputFolder: tempURL, chunkSize: pagesPerChunk)
        terminalCode = "pushd \(tempURL.path); python -m SimpleHTTPServer; popd"
        print("⚠️ This example requires a local webserver!\nOpen the Terminal app on your Mac and run the following command:\n\(terminalCode)")
        print("Cache Directory: \(SDK.shared.fileManager.cachesDirectory) + \(SDK.shared.cache.diskCache.cacheDirectory)")

        // Describe fetchable document and server location.
        // ** make sure to have a local webserver running or change URL **
        let pageCount = Document(url: documentURL, loadCheckpointIfAvailable: false).pageCount
        let chunks = StreamingDocumentDefinition.chunks(pages: Int(pageCount), chunkSize: pagesPerChunk)

        // Annotation logic: This example assumes you provide annotations from an external source.
        // To improve the example here we store annotations locally. Do not use this code in production.
        // Instead, use either your own annotation storage system, or a format like InstantJSON or XFDF.
        // Temporary URL - In a real application it is assumed you have a more sophisticated custom annotation storage.
        let annotationStorageURL = tempURL.appendingPathComponent("annotations")
        print("Annotation storage: \(annotationStorageURL.path)")
        var annotations = StreamingDocumentGenerator.loadAnnotations(from: annotationStorageURL)
        if annotations.isEmpty {
            annotations = StreamingDocumentGenerator.generateSampleAnnotations(pageCount: pageCount)
            StreamingDocumentGenerator.storeAnnotations(annotations: annotations, to: annotationStorageURL)
        }

        let streamingDefinition = StreamingDocumentDefinition(
            name: "Nutrient welcome.pdf",
            url: URL(string: "http://localhost:8000")!,
            chunks: chunks,
            // A production application should store the correct page sizes here and pass them down
            // to the clients as metadata, so appropriately sized placeholder pages can be shown.
            pageSizes: Array(repeating: CGSize(width: 768, height: 1024), count: Int(pageCount)),
            annotations: AnnotationContainer(annotations: annotations))
        streamingDocument = StreamingDocument(streamingDefinition: streamingDefinition)

        // Simple hook to save annotations externally. This misses notification deregistration.
        // In production code, ensure this handler is only created once to not save multiple times.
        observer = NotificationCenter.default.addObserver(forName: Document.willSaveAnnotations, object: streamingDocument, queue: .main) { notification in
            guard let document = notification.object as? StreamingDocument else { return }
            // Collect custom annotations from providers
            let allAnnotations = document.documentProviders.flatMap {
                // We can force-unwrap because we know each document has a container annotation provider.
                ($0.annotationManager.annotationProviders.first as! PDFContainerAnnotationProvider).allAnnotations
            }
            StreamingDocumentGenerator.storeAnnotations(annotations: allAnnotations, to: annotationStorageURL)
        }
    }

    static private func loadAnnotations(from annotationsFileURL: URL) -> [Annotation] {
        guard let data = FileManager.default.contents(atPath: annotationsFileURL.path) else { return [] }

        var annotationContainer: AnnotationContainer
        let decoder = JSONDecoder()
        do {
            annotationContainer = try decoder.decode(AnnotationContainer.self, from: data)
        } catch {
            annotationContainer = AnnotationContainer(annotations: [])
        }
        return annotationContainer.annotations
    }

    static private func storeAnnotations(annotations: [Annotation], to annotationsFileURL: URL) {
        // Since we split files, annotation index is changed; we need to preserve the original value.
        annotations.forEach { $0.storeOriginalPageIndex() }

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(AnnotationContainer(annotations: annotations)) else { return }

        if FileManager.default.fileExists(atPath: annotationsFileURL.path) {
            try? FileManager.default.removeItem(at: annotationsFileURL)
        }
        FileManager.default.createFile(atPath: annotationsFileURL.path, contents: data, attributes: nil)
    }

    /// Helper that generates example annotations: one per page.
    static private func generateSampleAnnotations(pageCount: UInt) -> [Annotation] {
        var annotations: [Annotation] = []
        for pageIndex in 0...pageCount {
            let annotation = InkAnnotation.sampleInkAnnotation(in: CGRect(x: 200, y: 200, width: 500, height: 500))
            annotation.pageIndex = pageIndex
            annotation.color = .random
            annotations.append(annotation)
        }
        return annotations
    }

    /// Show explain alert if there is no webserver running.
    func showExampleAlertIfNeeded(on controller: UIViewController) {
        DispatchQueue.global(qos: .utility).async {
            // Shortcut to improve example usability. Don't do this in production.
            if let data = try? Data(contentsOf: streamingDocument.streamingDefinition.documentURL(chunkIndex: 0)), !data.isEmpty { return }
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "This example requires a local HTTP server", message: "Use the iOS Simulator or Mac Catalyst to test this example. Open a terminal and type: '\(terminalCode)' to start the web server'", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Copy to Clipboard", style: .default, handler: { _ in
                    UIPasteboard.general.string = terminalCode
                }))
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                controller.present(alertController, animated: true, completion: nil)
            }
        }
    }

    /// Simple internal helper to split document into individual files made up of `chunkSize` pages each.
    /// For a real project, you want to run this on your backend.
    private static func splitDocument(fileURL: URL, outputFolder: URL, chunkSize: Int = 1) throws {
        let document = Document(url: fileURL, loadCheckpointIfAvailable: false)
        let fileName = fileURL.deletingPathExtension().lastPathComponent

        let chunks = StreamingDocumentDefinition.chunks(pages: Int(document.pageCount), chunkSize: chunkSize)
        var startPage = 0
        for (chunkIndex, chunk) in chunks.enumerated() {
            guard let configuration = Processor.Configuration(document: document) else { return }
            configuration.includeOnlyIndexes(IndexSet(integersIn: Range(NSRange(location: startPage, length: chunk))!))
            let processor = Processor(configuration: configuration, securityOptions: nil)

            // Generate pdf
            let outputURL = outputFolder.appendingPathComponent("\(fileName)_\(chunkIndex).pdf")
            // The processor doesn't overwrite files. Files might not yet exist on first run.
            do { try FileManager.default.removeItem(at: outputURL) } catch CocoaError.fileNoSuchFile { }
            try processor.write(toFileURL: outputURL)

            startPage += chunkSize
        }
        print("Split \(fileURL.path) into \(outputFolder.path) .")

        /// Generate thumbnails
        ///
        /// When limiting thumbnail size, take retina screens into account: width/height are in @1x format, don't go too low on quality.
        /// At the same time, if thumbnail size is too large, it can be larger than the corresponding PDF page.
        let MAX_THUMBNAIL_SIZE = CGSize(width: 400, height: 400)
        let THUMBNAIL_JPG_QUALITY: CGFloat = 0.75 // valid: >0.0 .. <=1.0
        startPage = 0
        while startPage < document.pageCount {
            let outputImageURL = outputFolder.appendingPathComponent("\(fileName)_\(startPage).jpg")
            let pageSize = document.pageInfoForPage(at: PageIndex(startPage))!.size
            // We use an existing helper to aspect-correct downscale the page size
            let scaledRect = AVMakeRect(aspectRatio: pageSize, insideRect: CGRect(origin: .zero, size: MAX_THUMBNAIL_SIZE))

            do { try FileManager.default.removeItem(at: outputImageURL) } catch CocoaError.fileNoSuchFile { }
            let image = try document.imageForPage(at: PageIndex(startPage), size: scaledRect.size, clippedTo: .zero, annotations: nil, options: nil)
            try image.jpegData(compressionQuality: THUMBNAIL_JPG_QUALITY)?.write(to: outputImageURL)
            startPage += 1
        }

        print("Generated thumbnails for \(fileURL.path) into \(outputFolder.path) .")
    }
}
