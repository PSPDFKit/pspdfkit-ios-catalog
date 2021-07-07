//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCSelectFreeTextAnnotationsExample.m' for the Objective-C version of this example.

class SelectFreeTextAnnotationsExample: Example {
    override init() {
        super.init()

        title = "Select Free Text Annotations for editing"
        category = .annotations
        priority = 330
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)

        // Create sample annotations
        for annotationNumber in 1...6 {
            let contents = "This is free-text annotation #\(annotationNumber)"
            let freeText = FreeTextAnnotation(contents: contents)
            freeText.fillColor = .yellow
            freeText.fontSize = 15
            freeText.boundingBox = CGRect(x: 300, y: annotationNumber * 100, width: 150, height: 150)
            freeText.sizeToFit()
            document.add(annotations: [freeText])
        }
        let pdfController = PDFViewController(document: document)

        // Iterate over all annotations and select them.
        weak var weakPDFController = pdfController
        let annotations = (document.annotationsForPage(at: 0, type: .freeText))
        for (index, freeText) in annotations.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(index + 1)) {
                let pageView: PDFPageView? = weakPDFController?.pageViewForPage(at: 0)
                pageView?.selectedAnnotations = [freeText]
                // Get the annotation view and directly invoke editing.
                let freeTextView = pageView?.annotationView(for: freeText) as? FreeTextAnnotationView
                freeTextView?.beginEditing()
            }
        }

        return pdfController
    }
}
