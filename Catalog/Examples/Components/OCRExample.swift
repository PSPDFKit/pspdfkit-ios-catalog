//
//  Copyright © 2020-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitOCR
import PSPDFKitUI

class OCRExample: Example {

    private var document: Document!
    private var tabbedController: OCRTabbedViewController!
    private var progress: Foundation.Progress!

    override init() {
        super.init()

        title = "OCR"
        contentDescription = "Performs optical character recognition (OCR) on the document."
        category = .componentsExamples
        priority = 1
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        document = AssetLoader.document(for: "Remote Work.pdf")

        let ocrButton = UIBarButtonItem(title: "Perform OCR", style: .plain, target: self, action: #selector(performOCRButtonTapped(_:)))

        tabbedController = OCRTabbedViewController()
        tabbedController.delegate = self
        tabbedController.documents = [document]
        let pdfController = tabbedController.pdfController
        pdfController.navigationItem.setRightBarButtonItems([ocrButton, pdfController.activityButtonItem, pdfController.annotationButtonItem, pdfController.searchButtonItem], animated: false)
        return tabbedController
    }

    @objc func performOCRButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "OCR", message: "This will convert inaccessible text to real text objects. The operation can take a few seconds.", preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "Continue", style: .default) { _ in
            self.performOCR(sender)
        }
        alert.addAction(continueAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.preferredAction = continueAction
        tabbedController.present(alert, animated: true, completion: nil)
    }

    func performOCR(_ sender: UIBarButtonItem) {
        sender.isEnabled = false

        let controller = tabbedController!

        let processorConfiguration = Processor.Configuration(document: document)!
        processorConfiguration.performOCROnPages(at: IndexSet(integer: 0), options: ProcessorOCROptions(language: .english))

        let processor = Processor(configuration: processorConfiguration, securityOptions: nil)
        controller.processor = processor
        processor.delegate = self
        let ocrURL = FileHelper.temporaryPDFFileURL(prefix: "ocr")

        let progress = Progress(totalUnitCount: Int64(document.pageCount + 1))
        self.progress = progress
        let provider = CoordinatedFileDataProvider(fileURL: ocrURL, progress: progress)
        let ocrDocument = Document(dataProviders: [provider])
        ocrDocument.title = document.title! + " (OCR)"
        controller.addDocument(ocrDocument, makeVisible: false, animated: true)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                try processor.write(toFileURL: ocrURL)
                progress.completedUnitCount = progress.totalUnitCount
                DispatchQueue.main.async {
                    controller.visibleDocument = ocrDocument
                    sender.isEnabled = true

                    let diffTime = CFAbsoluteTimeGetCurrent() - startTime
                    print("OCR took \(diffTime) seconds")
                }
            } catch {
                print(error)
            }
        }
    }
}

extension OCRExample: ProcessorDelegate {
    nonisolated func processor(_ processor: Processor, didProcessPage currentPage: UInt, totalPages: UInt) {
        DispatchQueue.main.async {
            self.progress.completedUnitCount = Int64(currentPage + 1)
        }
    }
}

extension OCRExample: PDFTabbedViewControllerDelegate {
    func tabbedPDFController(_ tabbedPDFController: PDFTabbedViewController, shouldClose document: Document) -> Bool {
        // Don't allow closing original document.
        if document == self.document {
            return false
        }
        // Don't allow closing documents where OCR is currently performed.
        return document.progress.isFinished
    }
}

private class OCRTabbedViewController: PDFTabbedViewController {
    var processor: Processor?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        processor?.cancel()
    }
}
