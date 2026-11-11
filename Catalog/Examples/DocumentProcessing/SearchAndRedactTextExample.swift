//
//  Copyright © 2018-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class SearchAndRedactTextExample: Example {

    override init() {
        super.init()

        title = "Search and Redact Text"
        contentDescription = "Shows how to search and redact text."
        category = .documentProcessing
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let redactionPrompt = UIAlertController(title: "Search and Redact Text", message: "Enter a word to redact:", preferredStyle: .alert)
        redactionPrompt.addTextField { textField in
            textField.text = "Nutrient"
        }

        redactionPrompt.addAction(UIAlertAction(title: "Redact", style: .default) { [weak redactionPrompt] _ in
            let wordToRedact = redactionPrompt?.textFields?.first?.text!
            let document = AssetLoader.document(for: .welcome)
            let status = StatusHUDItem.indeterminateProgress(withText: "Processing...")
            status.push(animated: true, on: delegate.currentViewController?.view.window)

            // Loop through all the pages of the document to find the search term.
            // In production we recommend doing this on a utility queue.
            // Note: The search is case sensitive.
            for pageIndex in 0..<document.pageCount {
                if let textParser = document.textParserForPage(at: pageIndex) {
                    textParser.words.forEach { word in
                        // Redact all the words that contain the search term.
                        if word.stringValue.range(of: wordToRedact!) != nil {
                            let redaction = self.createRedactionAnnotationFor(word: word, pageIndex: pageIndex)
                            document.add(annotations: [redaction])
                        }
                    }
                }
            }

            DispatchQueue.global(qos: .default).async {
                // Use Processor to create the newly redacted document.
                let processorConfiguration = Processor.Configuration(document: document)!
                processorConfiguration.applyRedactions()

                let redactedDocumentURL = FileHelper.temporaryPDFFileURL(prefix: "redacted")
                let processor = Processor(configuration: processorConfiguration, securityOptions: nil)
                try? processor.write(toFileURL: redactedDocumentURL)

                DispatchQueue.main.async {
                    status.pop(animated: true)
                    // Instantiate the redacted document and present it.
                    let redactedDocument = Document(url: redactedDocumentURL)
                    let pdfController = PDFViewController(document: redactedDocument)
                    delegate.currentViewController!.navigationController?.pushViewController(pdfController, animated: true)
                }
            }
        })

        redactionPrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        delegate.currentViewController!.present(redactionPrompt, animated: true)
        return nil
    }

    // MARK: Private
    private func createRedactionAnnotationFor(word: Word, pageIndex: PageIndex) -> RedactionAnnotation {
        let redactionRect = word.frame
        let redaction = RedactionAnnotation()
        redaction.boundingBox = redactionRect
        redaction.rects = [redactionRect]
        redaction.color = .orange
        redaction.fillColor = .black
        redaction.overlayText = "REDACTED"
        redaction.pageIndex = pageIndex
        return redaction
    }
}
