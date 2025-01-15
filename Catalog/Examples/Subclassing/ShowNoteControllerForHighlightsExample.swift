//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class ShowNoteControllerForHighlightsExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Directly show note controller for highlight annotations"
        contentDescription = "Automatically show the note controller when selecting highlight annotations."
        category = .subclassing
        priority = 160
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .cosmicContextForLife)

        let pageIndex: PageIndex = 1

        // Create some highlights.
        let textParser = document.textParserForPage(at: pageIndex)!
        let wordsToHighlight = textParser.words.filter { word in
            word.stringValue.localizedStandardContains("galax")
        }
        let annotations = wordsToHighlight.map { word -> HighlightAnnotation in
            let annotation = HighlightAnnotation()
            var tightBoundingBox = CGRect.zero
            annotation.rects = PSPDFRectsFromGlyphs(textParser.glyphs(in: word.range), &tightBoundingBox).map { $0.cgRectValue }
            // Add padding to the bounding box so the highlight’s rounded edges are not clipped.
            annotation.boundingBox = tightBoundingBox.insetBy(dx: -0.1 * tightBoundingBox.width, dy: -0.1 * tightBoundingBox.height)
            annotation.color = #colorLiteral(red: 1, green: 0.8639183044, blue: 0, alpha: 1)
            annotation.pageIndex = pageIndex
            return annotation
        }
        document.add(annotations: annotations)

        let pdfViewController = PDFViewController(document: document)
        pdfViewController.delegate = self
        pdfViewController.pageIndex = pageIndex

        return pdfViewController
    }

    // MARK: - PDFViewControllerDelegate

    func pdfViewController(_ pdfController: PDFViewController, didTapOn annotation: Annotation, annotationPoint: CGPoint, annotationView: (UIView & AnnotationPresenting)?, pageView: PDFPageView, viewPoint: CGPoint) -> Bool {
        // Make sure this was called for a highlight annotation.
        guard annotation.type == .highlight else {
            return false
        }
        // Show the comments directly.
        let viewController = pageView.presentComments(for: annotation)
        // If presenting the comments failed, then we want to fall back on
        // default touch handling.
        return viewController != nil
    }

}
