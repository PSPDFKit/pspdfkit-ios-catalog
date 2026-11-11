//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// A page view subclass that can show a progress indicator centered to the page.
final class StreamingPageView: PDFPageView {
    /// Enable or disable displaying the progress view. Animates.
    var showProgressIndicator: Bool = false {
        didSet {
            guard showProgressIndicator != oldValue else { return }
            UIView.animate(withDuration: 0.3) {
                self.progressView.alpha = self.showProgressIndicator ? 1 : 0
            }
        }
    }

    // Create and setup progress view lazily
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

    var streamingController: StreamingPDFViewController? {
        presentationContext?.pdfController as? StreamingPDFViewController
    }

    private func updateProgressIndicator() {
        // If the page is not backed by a file, it's still being loaded
        let documentProvider = presentationContext?.document?.documentProviderForPage(at: pageIndex)

        let fileIsDownloaded = documentProvider?.fileURL != nil
        showProgressIndicator = !fileIsDownloaded

        if !fileIsDownloaded {
            streamingController?.downloadFile(pageIndex: pageIndex)
        }
    }

    // Enabling this will enable thumbnails for large pages; but will disable annotation editing feedback.
//    override func renderTaskDidFinish(_ task: RenderTask) {
//        // Don't update the image with the placeholder PDF when the final document's not yet ready.
//        let documentProvider = presentationContext?.document?.documentProviderForPage(at: pageIndex)
//        let fileIsDownloaded = documentProvider?.fileURL != nil
//        if fileIsDownloaded {
//            super.renderTaskDidFinish(task)
//        }
//    }
}
