//
//  Copyright © 2016-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// Uses `PSPDFProcessor` to draw on all current pages of a document.
final class DrawOnPagesExample: Example {

    // MARK: Lifecycle

    override init() {
        super.init()

        title = "Draw Watermarks On Pages"
        contentDescription = "Uses PSPDFProcessor to draw watermarks on all current pages of a document"
        category = .documentProcessing
        priority = 14
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)
        guard let configuration = Processor.Configuration(document: document) else {
            fatalError("Processor configuration needs a valid document")
        }

        let renderDrawBlock: PDFRenderDrawBlock = { context, page, cropBox, _ in
            // Careful, this code is executed on background threads. Only use thread-safe drawing methods.
            let text = "PSPDF Live Watermark"
            let pageText = "On Page \(page + 1)"
            let stringDrawingContext = NSStringDrawingContext()
            stringDrawingContext.minimumScaleFactor = 0.1

            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 30),
                .foregroundColor: UIColor.red.withAlphaComponent(0.5)
            ]

            let pageTextAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.black.withAlphaComponent(0.5)
            ]
            // Add text in the bottom right corner
            context.translateBy(x: (cropBox.size.width / 2) + 30, y: cropBox.size.height - 200)
            text.draw(with: cropBox, options: .usesLineFragmentOrigin, attributes: textAttributes, context: stringDrawingContext)
            // Add second text below the first text
            context.translateBy(x: 0, y: 30)
            pageText.draw(with: cropBox, options: .usesLineFragmentOrigin, attributes: pageTextAttributes, context: stringDrawingContext)

        }

        configuration.drawOnAllCurrentPages(renderDrawBlock)

        let processedDocumentURL = FileHelper.temporaryPDFFileURL(prefix: "processed")

        // Process annotations.
        // `PSPDFProcessor` doesn't modify the document, but creates an output file instead.
        let processor = Processor(configuration: configuration, securityOptions: nil)
        processor.delegate = self
        try! processor.write(toFileURL: processedDocumentURL)

        let processedDocument = Document(url: processedDocumentURL)
        return PDFViewController(document: processedDocument)
    }
}

extension DrawOnPagesExample: ProcessorDelegate {
    nonisolated func processor(_ processor: Processor, didProcessPage currentPage: UInt, totalPages: UInt) {
        print("Progress: \(currentPage + 1) of \(totalPages)")
    }
}
