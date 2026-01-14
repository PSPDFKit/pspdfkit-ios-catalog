//
//  Copyright © 2017-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CustomAnnotationsWithMultipleFilesExample: Example {

    override init() {
        super.init()

        title = "Custom annotations with multiple files"
        category = .annotations
        priority = 400
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let dataProviders = ["Placeholder A", "Placeholder B", "Placeholder C", "Placeholder D"].map {
            CoordinatedFileDataProvider(fileURL: Bundle.main.url(forResource: $0, withExtension: "pdf", subdirectory: "Samples")!)
        }
        let document = Document(dataProviders: dataProviders)

        let aVideo = LinkAnnotation(url: (URL(string: "pspdfkit://localhost/Bundle/big_buck_bunny.mp4"))!)
        aVideo.boundingBox = CGRect(origin: .zero, size: document.pageInfoForPage(at: 5)!.size)
        aVideo.pageIndex = 5
        document.add(annotations: [aVideo])

        let anImage = LinkAnnotation(url: (URL(string: "pspdfkit://localhost/Bundle/exampleImage.jpg"))!)
        anImage.boundingBox = CGRect(origin: .zero, size: document.pageInfoForPage(at: 2)!.size)
        anImage.pageIndex = 2
        document.add(annotations: [anImage])

        let controller = PDFViewController(document: document)
        return controller

    }
}

// MARK: - Annotation Links to external documents

class AnnotationLinkstoExternalDocumentsExample: Example {

    override init() {
        super.init()

        title = "Annotation Links to external documents"
        contentDescription = "PDF links can point to pages within the same document, or also different documents or websites."
        category = .annotations
        priority = 600
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: "one.pdf")
        return PDFViewController(document: document)
    }
}
