//
//  Copyright © 2016-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// Shows how to create a new document with `PSPDFProcessor`.
final class NewDocumentCreationExample: Example {

    // MARK: Lifecycle

    override init() {
        super.init()

        title = "Create new document"
        contentDescription = "Uses PSPDFProcessor to create a new document"
        category = .documentProcessing
        priority = 11
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Set up configuration to create a new document.
        let configuration = Processor.Configuration()

        // Add an empty page with image in the bottom center.
        let backgroundColor = UIColor(red: 0.965, green: 0.953, blue: 0.906, alpha: 1)
        let image = UIImage(named: "exampleimage.jpg")!
        let emptyPageTemplate = PageTemplate.blank
        let newPageConfiguration = PDFNewPageConfiguration(pageTemplate: emptyPageTemplate) {
            $0.backgroundColor = backgroundColor
            $0.pageMargins = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            $0.item = ProcessorItem(image: image, jpegCompressionQuality: 0.8) { itemBuilder in
                itemBuilder.alignment = .bottom
                itemBuilder.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }
        }
        configuration.addNewPage(at: 0, configuration: newPageConfiguration)

        // Add a page with a pattern grid.
        configuration.addNewPage(at: 1, configuration: PDFNewPageConfiguration(pageTemplate: PageTemplate(pageType: .tiledPatternPage, identifier: .grid5mm)) {
            $0.backgroundColor = backgroundColor
        })

        // Add a page from a different document.
        let document = AssetLoader.document(for: .welcome)
        let documentTemplate = PageTemplate(document: document, sourcePageIndex: 7)
        configuration.addNewPage(at: 2, configuration: PDFNewPageConfiguration(pageTemplate: documentTemplate))

        let outputFileURL = FileHelper.temporaryPDFFileURL(prefix: "new-document")
        do {
            // Invoke processor to create new document.
            let processor = Processor(configuration: configuration, securityOptions: nil)
            processor.delegate = self
            try processor.write(toFileURL: outputFileURL)
        } catch {
            print("Error while processing document: \(error)")
        }

        // Init new document and view controller.
        let newDocument = Document(url: outputFileURL)
        let pdfController = PDFViewController(document: newDocument)

        return pdfController
    }
}

extension NewDocumentCreationExample: ProcessorDelegate {
    nonisolated func processor(_ processor: Processor, didProcessPage currentPage: UInt, totalPages: UInt) {
        print("Progress: \(currentPage + 1) of \(totalPages)")
    }
}
