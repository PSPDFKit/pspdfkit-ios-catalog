//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

public struct DownloadJob: Sendable {
    let downloadUrl: URL
    let chunkIndex: Int
    let priority: DownloadPriority

    public enum DownloadPriority: Sendable {
        case normal
        case high
    }
}

public extension NSNotification.Name {
    static let StreamingDownloadCoordinatorDidDownloadFile = NSNotification.Name("StreamingDownloadCoordinatorDidDownloadFile")
}

class StreamingDownloadCoordinator {
    static let shared = StreamingDownloadCoordinator()
    var activeStreamingDefinition: StreamingDocumentDefinition?

    var fileDownloads: [URL: URLSessionTask] = [:]
    fileprivate var queuedSessions: [DownloadJob] = []

    let queueForFileDownloads = DispatchQueue(label: "fileDownloads.queue", attributes: .concurrent)
    let queueForQueuedSessions = DispatchQueue(label: "queuedSessions.queue", attributes: .concurrent)

    static let simultaneousDownloads = 2
    static let DEBUG_additionalSimulatedDownloadDelayInSeconds: Double = 0.5

    func downloadFile(pageIndex: PageIndex) {
        let chunkIndex = activeStreamingDefinition!.chunkIndex(for: pageIndex)
        downloadChunk(chunkIndex: chunkIndex, priority: .high, prefetch: true)
    }

    private func downloadChunk(chunkIndex: Int, priority: DownloadJob.DownloadPriority, prefetch: Bool) {
        let documentURL = activeStreamingDefinition!.documentURL(chunkIndex: chunkIndex)
        fetchFile(url: documentURL, chunkIndex: chunkIndex, priority: priority, prefetch: prefetch)
    }

    private func fetchFile(url: URL, chunkIndex: Int, priority: DownloadJob.DownloadPriority, prefetch: Bool) {
        precondition(Thread.isMainThread)

        let fileDownload = getFileDownloadFrom(url: url)
        let queuedJob = getQueuedSessionTask(url: url)
        if fileDownload != nil || queuedJob != nil {
            print("Download in progress for: \(url.lastPathComponent). Cancelling.")
            return
        }

        let job = DownloadJob(downloadUrl: url, chunkIndex: chunkIndex, priority: priority)
        queue(job: job)
        dequeueTask()

        // Pre-fetch next chunk
        if prefetch {
            prefetchNextChunk(previousJob: job)
        }
    }

    private func downloadTask(for job: DownloadJob) -> URLSessionTask {
        if let activeStreamingDefinition, job.chunkIndex >= activeStreamingDefinition.chunks.count {
            preconditionFailure("ChunkIndex out of bounds.")
        }

        return URLSession.shared.downloadTask(with: job.downloadUrl) { localURL, _, error in
            try? FileManager.default.createDirectory(at: self.activeStreamingDefinition!.downloadFolder, withIntermediateDirectories: true, attributes: nil)

            if let localURL {
                let targetURL = self.activeStreamingDefinition!.localURLFrom(remoteUrl: job.downloadUrl)
                // Careful: The copy must happen directly, else download task's temp url might already be cleared up.
                _ = try? FileManager.default.replaceItemAt(targetURL, withItemAt: localURL)

                // Dispatch to main thread and optionally delay download (to test slow network conditions)
                DispatchQueue.main.asyncAfter(deadline: .now() + StreamingDownloadCoordinator.DEBUG_additionalSimulatedDownloadDelayInSeconds) {
                    self.queueForFileDownloads.sync(flags: .barrier) {
                        self.fileDownloads[job.downloadUrl] = nil
                    }
                    print("Downloaded: \(targetURL.lastPathComponent)")
                    NotificationCenter.default.post(name: .StreamingDownloadCoordinatorDidDownloadFile, object: self, userInfo: ["chunkIndex": job.chunkIndex, "targetURL": targetURL])

                    // Queue next chunk if nothing is lined up yet
                    if self.queuedSessions.isEmpty {
                        self.prefetchNextChunk(previousJob: job)
                    }

                    self.dequeueTask()
                }
            } else {
                print("Error: \(String(describing: error))")

                self.queueForFileDownloads.sync(flags: .barrier) {
                    self.fileDownloads[job.downloadUrl] = nil
                }
            }
        }
    }

    private func prefetchNextChunk(previousJob: DownloadJob) {
        let chunkIndex = previousJob.chunkIndex + 1
        if chunkIndex < self.activeStreamingDefinition!.chunks.count {
            self.downloadChunk(chunkIndex: chunkIndex, priority: .normal, prefetch: false)
        }
    }

    private func getFileDownloadFrom(url: URL) -> URLSessionTask? {
        queueForFileDownloads.sync {
            return fileDownloads[url]
        }
    }

    private func queue(job: DownloadJob) {
        print("Queueing \(job.downloadUrl.lastPathComponent)")
        if let activeStreamingDefinition, job.chunkIndex >= activeStreamingDefinition.chunks.count {
            preconditionFailure("ChunkIndex out of bounds.")
        }
        self.queueForQueuedSessions.sync(flags: .barrier) {
            queuedSessions.append(job)
        }
    }

    private func getQueuedSessionTask(url: URL) -> DownloadJob? {
        queueForQueuedSessions.sync {
            return queuedSessions.first { $0.downloadUrl == url }
        }
    }

    private func dequeueTask() {
        if fileDownloads.count >= StreamingDownloadCoordinator.simultaneousDownloads { return }
        guard !queuedSessions.isEmpty else { return }

        let jobIndex = queuedSessions.firstIndex { $0.priority == .high } ?? 0
        let nextJob = queuedSessions.remove(at: jobIndex)

        let task = downloadTask(for: nextJob)
        self.queueForFileDownloads.sync(flags: .barrier) {
            fileDownloads[nextJob.downloadUrl] = task
        }
        print("Downloading: \(nextJob.downloadUrl.lastPathComponent)")
        task.resume()
    }

    func cancelAll() {
        queueForFileDownloads.sync {
            fileDownloads.values.forEach { $0.cancel() }
            fileDownloads.removeAll()
        }
    }

}
