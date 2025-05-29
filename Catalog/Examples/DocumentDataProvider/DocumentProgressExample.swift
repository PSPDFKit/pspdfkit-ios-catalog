//
//  Copyright © 2017-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// This example showing asynchronous document loading.
/// The downloaded document can be modified, such as adding annotations.
/// If you don’t need such fine-grained control and the document can be read-only, see the simpler `RemoteDocumentURLExample` instead.
class DocumentProgressExample: Example {

    let destinationFileURL = FileHelper.temporaryPDFFileURL(prefix: "document")
    let remoteURL = URL(string: "https://github.com/PSPDFKit/pspdfkit-ios-catalog/raw/master/Samples/Magazine.pdf")!
    var downloader: Downloader?

    override init() {
        super.init()
        title = "Download and annotate a PDF from a remote URL"
        contentDescription = "Downloads a PDF using URLSession. Shows progress using the data provider progress property."
        category = .documentDataProvider
        priority = 3
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let cancelButton = UIBarButtonItem(title: localizedString("Cancel"), style: .plain, target: self, action: #selector(cancelButtonPressed))

        downloader?.cleanup()
        downloader = Downloader(remoteURL: remoteURL, destinationFileURL: destinationFileURL)
        downloader?.didFinishDownloading = { _ in
            cancelButton.isEnabled = false
        }

        // Configure the data provider with our NSProgress instance.
        let provider = CoordinatedFileDataProvider(fileURL: destinationFileURL, progress: downloader?.progress)
        let document = Document(dataProviders: [provider])
        let controller = PDFViewController(document: document)

        controller.navigationItem.setRightBarButtonItems([cancelButton] + controller.navigationItem.rightBarButtonItems!, animated: false)

        return controller
    }

    @objc func cancelButtonPressed(sender: UIBarButtonItem?) {
        sender?.isEnabled = false
        guard let downloader = self.downloader else { return }
        downloader.progress.cancel()
        downloader.cleanup()
    }
}

class Downloader: NSObject {

    let progress = Progress(totalUnitCount: 100)
    let downloadProgress = Progress(totalUnitCount: 1)
    let moveProgress = Progress(totalUnitCount: 1)

    let destinationFileURL: URL
    let remoteURL: URL

    var session: URLSession?
    var task: URLSessionDownloadTask?

    var didFinishDownloading: ((_ location: URL) -> Void)?

    init(remoteURL: URL, destinationFileURL: URL) {
        self.remoteURL = remoteURL
        self.destinationFileURL = destinationFileURL

        super.init()

        // Download the file using URLSession API.
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        self.session = session
        let task = session.downloadTask(with: remoteURL)
        self.task = task
        task.resume()

        // Setup progress hierarchy. The download should take much longer than the final move.
        progress.addChild(downloadProgress, withPendingUnitCount: 99)
        progress.addChild(moveProgress, withPendingUnitCount: 1)
    }

    func cleanup() {
        do {
            task?.cancel()
            session?.invalidateAndCancel()

            try FileManager().removeItem(at: destinationFileURL)
        } catch {
            print(error)
        }
    }
}

extension Downloader: URLSessionDelegate, URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager().moveItem(at: location, to: destinationFileURL)
            // We must ensure that the complete progress (`progress`) only completes when the file is already at its final location.
            moveProgress.completedUnitCount = moveProgress.totalUnitCount
            didFinishDownloading?(location)
        } catch {
            print(error)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        downloadProgress.totalUnitCount = totalBytesExpectedToWrite
        downloadProgress.completedUnitCount = totalBytesWritten
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            print(error.localizedDescription)
            // Complete the progress.
            progress.completedUnitCount = progress.totalUnitCount
        }
    }
}
