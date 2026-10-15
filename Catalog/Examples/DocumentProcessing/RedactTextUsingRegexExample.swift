//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class RedactTextUsingRegexExample: Example {

    override init() {
        super.init()

        title = "Redact Text Using Regular Expressions"
        contentDescription = "Shows how to redact URLs using a regex pattern."
        category = .documentProcessing
        priority = 16
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .web)
        let status = StatusHUDItem.indeterminateProgress(withText: "Processing...")
        status.push(animated: true, on: delegate.currentViewController?.view.window)

        // The regex pattern for URLs.
        let urlPattern = #"[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)"#
        let urlRegularExpression = try! NSRegularExpression(pattern: urlPattern)

        // Loop through all the pages in the document to find URLs.
        // In production we recommend doing this on a utility queue.
        for pageIndex in 0..<document.pageCount {
            if let textParser = document.textParserForPage(at: pageIndex) {
                textParser.words.forEach { word in
                    let wordString = word.stringValue
                    let range = NSRange(wordString.startIndex..<wordString.endIndex, in: wordString)
                    // Redact all the words that match the regex.
                    let isValidURL = urlRegularExpression.numberOfMatches(in: wordString, options: [], range: range) > 0
                    if isValidURL {
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
