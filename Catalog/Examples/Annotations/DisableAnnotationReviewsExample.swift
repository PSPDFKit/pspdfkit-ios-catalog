//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class DisableAnnotationReviewsExample: Example {

    override init() {
        super.init()

        title = "Disable Annotation Reviews"
        contentDescription = "Shows how to use Document Features to disable viewing and setting annotation reviews."
        category = .annotations
        priority = 2010
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        // Add the custom source to the document's features.
        document.features.add([DisableAnnotationReviewsDocumentFeaturesSource()])

        return PDFViewController(document: document)
    }
}

private class DisableAnnotationReviewsDocumentFeaturesSource: NSObject, PDFDocumentFeaturesSource {

    weak var features: PDFDocumentFeatures?

    // Return false to disable annotation reviews.
    var canShowAnnotationReviews: Bool {
        false
    }
}
