//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class BlendModeMenuForMarkupAnnotationsExample: Example {

    override init() {
        super.init()

        title = "Show Blend Mode menu item when selecting a highlight annotation"
        contentDescription = "Shows how to add the Blend Mode menu item in the highlight annotation selection menu."
        category = .annotations
        priority = 204
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        document.annotationSaveMode = .embedded

        // Add highlight annotation if there isn't one already.
        let pageIndex: PageIndex = 0
        let highlights = document.annotationsForPage(at: pageIndex, type: .highlight)
        if highlights.isEmpty {
            let textParser = document.textParserForPage(at: pageIndex)!
            for word in textParser.words where word.stringValue == "PSPDFKit" {
                guard let range = Range<Int>(word.range) else {
                    continue
                }
                let highlightAnnotation = HighlightAnnotation.textOverlayAnnotation(with: [Glyph](textParser.glyphs[range]))!
                highlightAnnotation.color = .yellow
                highlightAnnotation.pageIndex = pageIndex
                document.add(annotations: [highlightAnnotation])
            }
        }
        let controller = BlendModeMenuForMarkupsViewController(document: document) {
            // Configure the properties for highlight annotations to show the blend mode menu item.
            var annotationProperties = $0.propertiesForAnnotations
            annotationProperties[.highlight] = [[.blendMode, .color, .alpha]] as [[AnnotationStyle.Key]]
            $0.propertiesForAnnotations = annotationProperties
        }
        return controller
    }
}

private class BlendModeMenuForMarkupsViewController: PDFViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Select the highlight annotation to show the Inspector menu.
        let pageView = self.pageViewForPage(at: 0)
        guard let highlightAnnotation = self.document?.annotationsForPage(at: pageIndex, type: .highlight).first else { return }

        pageView?.select(highlightAnnotation, animated: true)
    }
}
