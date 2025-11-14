//
//  Copyright © 2020-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

final class FaceRedactionExample: Example {

    // MARK: Lifecycle

    override init() {
        super.init()

        title = "Face Redaction"
        contentDescription = "Shows how to redact faces in documents with PSPDFProcessor."
        category = .documentProcessing
        priority = 12
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Flight Attendants.pdf")

        // If there are any existing redact annotations, remove them.
        for pageIndex in 0..<document.pageCount {
            let existingRedactAnnotations = document.annotationsForPage(at: pageIndex, type: .redaction)
            document.remove(annotations: existingRedactAnnotations)
        }

        let status = StatusHUDItem.indeterminateProgress(withText: "Detecting faces...")
        status.setHUDStyle(.black)
        status.push(animated: true, on: delegate.currentViewController?.view.window, completion: nil)

        // Prepare a face detector. As this is an expensive operation, try to reuse this instance as much as possible.
        #if targetEnvironment(simulator)
        // `CIDetectors` don't work with high accuracy in simulators for some reason.
        // A similar problem is described here https://developer.apple.com/forums/thread/722685,
        // but there's no solution aside from forcing the low accuracy on simulators for now
        let options = [CIDetectorAccuracy: CIDetectorAccuracyLow]
        #else
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        #endif

        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!

        // Perform this expensive work on a background queue.
        DispatchQueue.global(qos: .background).async {
            var documentRedactionAnnotations: [RedactionAnnotation] = []
            for pageIndex in 0..<document.pageCount {
                // Render this page. For efficiency, we can work with a scaled page render and still get good results.
                let scaleFactor: CGFloat = 1 / 3.0
                let pageSize = document.pageInfoForPage(at: pageIndex)!.size
                let scaledPageSize = CGSize(width: pageSize.width * scaleFactor, height: pageSize.height * scaleFactor)
                let renderedPage = try! document.imageForPage(at: pageIndex, size: scaledPageSize, clippedTo: .zero, annotations: nil, options: nil)
                // Detect faces on the rendered page.
                let ciImage = CIImage(cgImage: renderedPage.cgImage!)
                let transform = CGAffineTransform(scaleX: 1 / (scaleFactor * renderedPage.scale), y: 1 / (scaleFactor * renderedPage.scale))
                let faces = faceDetector.features(in: ciImage, options: nil)
                // Place a redaction annotation on top of each detected face.
                let redactionAnnotations = faces.map { face -> RedactionAnnotation in
                    let faceBounds = face.bounds.applying(transform)
                    let redaction = RedactionAnnotation()
                    redaction.boundingBox = faceBounds
                    redaction.rects = [faceBounds]
                    redaction.color = .orange
                    redaction.fillColor = .black
                    redaction.outlineColor = .green
                    redaction.pageIndex = pageIndex
                    return redaction
                }
                documentRedactionAnnotations.append(contentsOf: redactionAnnotations)
            }
            // Add the detected redaction annotations on the main queue and hide the progress window.
            DispatchQueue.main.async {
                document.add(annotations: documentRedactionAnnotations)
                let statusDone = StatusHUDItem.success(withText: "Done")
                statusDone.pushAndPop(withDelay: 1, animated: true, on: delegate.currentViewController?.view.window)
                status.pop(animated: true)
            }
        }

        return FaceRedactionPDFViewController(document: document)
    }

    final class FaceRedactionPDFViewController: PDFViewController {
        override func commonInit(with document: Document?, configuration: PDFConfiguration) {
            super.commonInit(with: document, configuration: configuration)
            let redactButton = UIBarButtonItem(title: "Redact", style: .plain, target: self, action: #selector(applyRedactions))
            navigationItem.setRightBarButtonItems([annotationButtonItem, activityButtonItem, outlineButtonItem, redactButton], for: .document, animated: false)
        }

        @objc func applyRedactions() {
            let processorConfiguration = Processor.Configuration(document: document)!
            processorConfiguration.applyRedactions()

            let redactedDocumentURL = FileHelper.temporaryPDFFileURL(prefix: "redacted")
            let processor = Processor(configuration: processorConfiguration, securityOptions: nil)
            try! processor.write(toFileURL: redactedDocumentURL)

            self.document = Document(url: redactedDocumentURL)
        }
    }
}
