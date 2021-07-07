//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

/// This helper is used in combination with the streaming example, to split the page
/// and explain how a local server should be started in order to run the example.
///
/// In your app, you do not need all of this logic, as the document should be hosted on a server, not on your local Mac.
struct StreamingDocumentHelper {
    let fetchableDocument: FetchableDocument
    private let terminalCode: String

    init() {
        let pagesPerChunk = 2
        // Load document and split into a temporary folder
        let documentURL = AssetLoader.document(for: .quickStart).fileURL!
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        try? StreamingDocumentHelper.splitDocument(fileURL: documentURL, outputFolder: tempURL, chunkSize: pagesPerChunk)
        terminalCode = "pushd \(tempURL.path); python -m SimpleHTTPServer; popd"
        print("⚠️ This example requires a local webserver!\nOpen the Terminal app on your Mac and run the following command:\n\(terminalCode)")

        // Describe fetchable document and server location.
        // ** make sure to have a local webserver running or change URL **
        let pageCount = Document(url: documentURL, loadCheckpointIfAvailable: false).pageCount
        let chunks = FetchableDocument.chunks(pages: Int(pageCount), chunkSize: pagesPerChunk)
        fetchableDocument = FetchableDocument(name: "PSPDFKit 10 QuickStart Guide.pdf",
                                                  url: URL(string: "http://localhost:8000")!,
                                                  chunks: chunks,
                                                  pageSize: CGSize(width: 768, height: 1024))
    }

    /// Show explain alert if there is no webserver running.
    func showExampleAlertIfNeeded(on controller: UIViewController) {
        DispatchQueue.global(qos: .utility).async {
            if let data = try? Data(contentsOf: fetchableDocument.buildDownloadURL(chunkIndex: 0)), !data.isEmpty { return }
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

        let chunks = FetchableDocument.chunks(pages: Int(document.pageCount), chunkSize: chunkSize)
        var startPage = 0
        for (chunkIndex, chunk) in chunks.enumerated() {
            guard let configuration = Processor.Configuration(document: document) else { return }
            configuration.includeOnlyIndexes(IndexSet(integersIn: Range(NSRange(location: startPage, length: chunk))!))
            let processor = Processor(configuration: configuration, securityOptions: nil)

            let outputURL = outputFolder.appendingPathComponent("\(fileName)_\(chunkIndex).pdf")
            // The processor doesn't overwrite files. Files might not yet exist on first run.
            do { try FileManager.default.removeItem(at: outputURL) } catch CocoaError.fileNoSuchFile { }
            try processor.write(toFileURL: outputURL)
            startPage += chunkSize
        }
        print("Split \(fileURL.path) into \(outputFolder.path).")
    }

    /// Structure that defines all necessary information to dynamcally fetch documents, build, download and load them from cache.
    struct FetchableDocument: Codable {
        /// The name of the document (MyDocument.pdf)
        let name: String
        /// The remote URL of the document, where the individual chunks are accessible
        /// See buildDownloadURL for details.
        let url: URL
        /// The number of chunks. Each chunk corresponds to a number of pages.
        let chunks: [Int]
        /// Page size is uniform for simplicity.
        let pageSize: CGSize

        /// Helper to define where this document will be stored.
        /// The scheme is AppData/Documents/DocumentName
        var downloadFolder: URL {
            let documentFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return documentFolderURL.appendingPathComponent(name.replacingOccurrences(of: ".pdf", with: ""))
        }

        /// Calculate chunks for a specific page size
        static func chunks(pages: Int, chunkSize: Int = 1) -> [Int] {
            var pagesLeft = pages
            var chunks = [Int]()
            while pagesLeft > 0 {
                if pagesLeft >= chunkSize {
                    chunks.append(chunkSize)
                    pagesLeft -= chunkSize
                } else {
                    chunks.append(pagesLeft)
                    break
                }
            }
            return chunks
        }

        /// Build document backed by either files or temporary data.
        /// Accesses disk to check for exisiting chunks.
        func buildDocument() -> Document {
            var dataProviders = [DataProviding]()
            for index in chunks.indices {
                let url = buildDownloadURL(chunkIndex: index)
                let fileURL = localURLFrom(remoteUrl: url)
                // Check if we already have files on disk
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    dataProviders.append(FileDataProvider(fileURL: fileURL))
                } else {
                    dataProviders.append(DataContainerProvider(data: blankPDFData(size: pageSize, pages: chunks[index])))
                }
            }
            return Document(dataProviders: dataProviders)
        }

        func pagesFor(chunkIndex: Int) -> Range<Int> {
            var startPage = 0
            for index in 0..<chunkIndex {
                startPage += chunks[index]
            }
            return startPage ..< startPage + chunks[chunkIndex]
        }

        /// Helper that starts to download all files.
        func downloadAllFiles(updateHandler: @escaping ((_ chunkIndex: Int, _ fileURL: URL) -> Void)) {
            try? FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true, attributes: nil)

            // Start downloading all the pages. This could be made smarter to prioritize the current page.
            for index in chunks.indices {
                let url = buildDownloadURL(chunkIndex: index)
                fetchFile(url: url, targetFolderURL: downloadFolder) { downloadStatus in
                    switch downloadStatus {
                    case .success(let URL):
                        print("Downloaded: \(URL.lastPathComponent)")
                        updateHandler(index, URL)
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                }
            }
        }

        /// Converts remote URL to local URL.
        private func localURLFrom(remoteUrl: URL) -> URL {
            downloadFolder.appendingPathComponent(remoteUrl.lastPathComponent)
        }

        /// Builds the download URL from the host, document name and chunk.
        fileprivate func buildDownloadURL(chunkIndex: Int) -> URL {
            let fileName = name.replacingOccurrences(of: ".pdf", with: "")
            let escapedName = "\(fileName)_\(chunkIndex).pdf".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            return URL(string: "\(url)/\(escapedName)")!
        }

        /// Simple async URL fetcher that returns a completion handler.
        private func fetchFile(url: URL, targetFolderURL: URL, completion: @escaping (_ fileURL: Result<URL, Error>) -> Void) {
            let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
                // Simulate slow connection!
                sleep(1)

                if let localURL = localURL {
                    let targetURL = localURLFrom(remoteUrl: url)
                    _ = try? FileManager.default.replaceItemAt(targetURL, withItemAt: localURL)
                    completion(.success(targetURL))
                } else {
                    completion(.failure(error!))
                }
            }
            task.resume()
        }

        /// Helper to create a blank white PDF with a specific size.
        private func blankPDFData(size: CGSize, pages: Int = 1) -> Data {
            UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height),
                                  format: UIGraphicsPDFRendererFormat())
                .pdfData {
                    for _ in 0..<pages {
                        $0.beginPage()
                    }
                }
        }
    }
}
