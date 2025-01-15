//
//  Copyright © 2018-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

final class RedactionExample: Example {

    // MARK: Lifecycle

    override init() {
        super.init()

        title = "Redaction"
        contentDescription = "Shows how to redact text with Processor."
        category = .documentProcessing
        priority = 12
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)
        // Change the UID so the annotations we add in this example
        // don't show up in other examples using this document,
        // and are saved to an external file.
        document.uid = "Welcome Redaction"

        // If there are any existing redact annotations, remove them.
        let existingRedactAnnotations = document.annotations(at: 0, type: RedactionAnnotation.self)
        document.remove(annotations: existingRedactAnnotations)

        // Add a redact annotation over the word 'Welcome' on the first page.
        if let textParser = document.textParserForPage(at: 0),
            let wordToRedact = textParser.words.first(where: { $0.stringValue == "Welcome" }) {

            let redactionRect = wordToRedact.frame

            let redaction = RedactionAnnotation()
            redaction.boundingBox = redactionRect
            redaction.rects = [redactionRect]
            redaction.color = .orange
            redaction.fillColor = .black
            redaction.outlineColor = .green
            redaction.overlayText = "REDACTED"

            document.add(annotations: [redaction])
        }

        return RedactionPDFViewController(document: document)
    }

    final class RedactionPDFViewController: PDFViewController {
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
