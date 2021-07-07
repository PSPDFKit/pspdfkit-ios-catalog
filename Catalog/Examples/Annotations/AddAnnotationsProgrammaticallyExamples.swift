//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCAddAnnotationsProgrammaticallyExamples.m' for the Objective-C version of this example.

class AddInkAnnotationProgrammaticallyExample: Example {

    override init() {
        super.init()

        title = "Add Ink Annotation"
        category = .annotations
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled

        // add ink annotation if there isn't one already.
        let targetPage: PageIndex = 0
        let annotation = InkAnnotation()

        // example how to create a line rect.
        let lines = [
            [CGPoint(x: 100, y: 100), CGPoint(x: 100, y: 200), CGPoint(x: 150, y: 300)],     // first line
            [CGPoint(x: 200, y: 100), CGPoint(x: 200, y: 200), CGPoint(x: 250, y: 300)]
        ]

        // convert view line points into PDF line points.
        let pageInfo = document.pageInfoForPage(at: targetPage)!
        let viewRect = UIScreen.main.bounds // this is your drawing view rect - we don't have one yet, so lets just assume the whole screen for this example. You can also directly write the points in PDF coordinate space, then you don't need to convert, but usually your user draws and you need to convert the points afterwards.
        annotation.lineWidth = 5
        annotation.lines = ConvertToPDFLines(viewLines: lines, pageInfo: pageInfo, viewBounds: viewRect)

        annotation.color = UIColor(red: 0.667, green: 0.279, blue: 0.748, alpha: 1)
        annotation.pageIndex = targetPage
        document.add(annotations: [annotation])

        let controller = PDFViewController(document: document)
        return controller
    }
}

class AddHighlightAnnotationProgrammaticallyExample: Example {

    override init() {
        super.init()

        title = "Add Highlight Annotations"
        category = .annotations
        priority = 20
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled

        // Let's create a highlight for all occurrences of "Business".
        var annotationCounter = 0
        for pageIndex: PageIndex in 0..<document.pageCount {
            guard let textParser = document.textParserForPage(at: pageIndex) else { continue }
            for word in textParser.words where word.stringValue == "Business" {
                guard let range = Range<Int>(word.range) else {
                    continue
                }
                let annotation = HighlightAnnotation.textOverlayAnnotation(with: [Glyph](textParser.glyphs[range]))!
                annotation.color = .orange
                annotation.contents = "This is an automatically created highlight #\(annotationCounter)"
                annotation.pageIndex = pageIndex

                document.add(annotations: [annotation])
                annotationCounter += 1
            }
        }

        // Highlight an entire text selection on the second page, in yellow.
        let pageIndex: PageIndex = 1
        // Text selection rect in PDF coordinates for the first paragraph of the second page.
        let textSelectionRect = CGRect(x: 36, y: 547, width: 238, height: 135)
        let glyphs = document.objects(atPDFRect: textSelectionRect, pageIndex: pageIndex, options: [.extractGlyphs: true as NSNumber])[.glyphs] as! [Glyph]
        let annotation = HighlightAnnotation.textOverlayAnnotation(with: glyphs)!
        annotation.color = UIColor.yellow
        annotation.contents = "This is an automatically created highlight #\(annotationCounter)"
        annotation.pageIndex = pageIndex
        document.add(annotations: [annotation])

        let controller = PDFViewController(document: document)
        controller.pageIndex = pageIndex
        return controller
    }
}

class AddNoteAnnotationProgrammaticallyExample: Example {

    override init() {
        super.init()

        title = "Add Note Annotation"
        category = .annotations
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let documentURL = AssetLoader.assetURL(for: .annualReport)
        let data = try? Data(contentsOf: documentURL, options: .mappedIfSafe)

        // we use a NSData document here but it'll work even better with a file-based variant.
        let document = Document(dataProviders: [DataContainerProvider(data: data!)])
        document.annotationSaveMode = .disabled
        document.title = "Programmatically create annotations"

        var annotations = [Annotation]()
        let maxHeight = document.pageInfoForPage(at: 0)!.size.height
        for i in 0...4 {
            let noteAnnotation = NoteAnnotation()
            // width/height will be ignored for note annotations.
            noteAnnotation.boundingBox = CGRect(x: 100, y: (50 + CGFloat(i) * CGFloat(maxHeight / 5)), width: 32, height: 32)
            noteAnnotation.contents = "Note #\(5 - i)"
            annotations.append(noteAnnotation)
        }
        document.add(annotations: annotations)

        let pdfController = PDFViewController(document: document)
        return pdfController
    }
}

class AddPolyLineAnnotationProgrammaticallyExample: Example {

    override init() {
        super.init()

        title = "Add PolyLine Annotation"
        category = .annotations
        priority = 40
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled

        // Add shape annotation if there isn't one already.
        let pageIndex: PageIndex = 0
        let polyLines = document.annotationsForPage(at: pageIndex, type: .polyLine)
        if polyLines.isEmpty {
            let polyLine = PolyLineAnnotation()
            polyLine.points = [CGPoint(x: 152, y: 333), CGPoint(x: 167, y: 372), CGPoint(x: 231, y: 385), CGPoint(x: 278, y: 354), CGPoint(x: 215, y: 322)]
            polyLine.color = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
            polyLine.fillColor = .yellow
            polyLine.lineEnd2 = .closedArrow
            polyLine.lineWidth = 5
            polyLine.pageIndex = pageIndex
            document.add(annotations: [polyLine])
        }

        let controller = PDFViewController(document: document)
        controller.navigationItem.setRightBarButtonItems([controller.thumbnailsButtonItem, controller.outlineButtonItem, controller.openInButtonItem, controller.searchButtonItem], for: .document, animated: false)
        return controller
    }
}

class AddShapeAnnotationProgrammaticallyExample: Example {

    override init() {
        super.init()

        title = "Add Shape Annotation"
        category = .annotations
        priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled

        // add shape annotation if there isn't one already.
        let pageIndex: PageIndex = 0
        let squares = document.annotationsForPage(at: pageIndex, type: .square)
        if squares.isEmpty {
            let annotation = SquareAnnotation()
            annotation.boundingBox = CGRect(origin: .zero, size: document.pageInfoForPage(at: pageIndex)!.size).insetBy(dx: 100, dy: 100)
            annotation.color = UIColor(red: 0, green: 100 / 255, blue: 0, alpha: 1)
            annotation.fillColor = annotation.color
            annotation.alpha = 0.5
            annotation.pageIndex = pageIndex

            document.add(annotations: [annotation])
        }

        let controller = PDFViewController(document: document) {
            $0.isTextSelectionEnabled = false
        }
        controller.navigationItem.setRightBarButtonItems([controller.thumbnailsButtonItem, controller.openInButtonItem, controller.searchButtonItem], for: .document, animated: false)
        return controller
    }
}

class AddVectorStampAnnotationProgrammaticallyExample: Example {

    override init() {
        super.init()

        title = "Add Vector Stamp Annotation"
        category = .annotations
        priority = 60
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        let logoURL = AssetLoader.assetURL(for: "PSPDFKit Logo.pdf")

        // Add stamp annotation if there isn't one already.
        let pageIndex: PageIndex = 0
        let stamps = document.annotationsForPage(at: pageIndex, type: .stamp)
        if stamps.isEmpty {
            // Add a transparent stamp annotation using the appearance stream generator.
            let stampAnnotation = StampAnnotation()
            stampAnnotation.boundingBox = CGRect(x: 180.0, y: 150.0, width: 444.0, height: 500.0)
            stampAnnotation.appearanceStreamGenerator = FileAppearanceStreamGenerator(fileURL: logoURL)
            stampAnnotation.pageIndex = pageIndex
            document.add(annotations: [stampAnnotation])
        }
        let pdfController = PDFViewController(document: document)
        return pdfController
    }
}

class AddFileAnnotationProgrammaticallyExample: Example {

    override init() {
        super.init()

        title = "Add File Annotation With Embedded File"
        category = .annotations
        priority = 70
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let embeddedFileURL = AssetLoader.assetURL(for: "PSPDFKit Logo.pdf")

        // Add file annotation if there isn't one already.
        let pageIndex: PageIndex = 0
        let fileAnnotations = document.annotationsForPage(at: pageIndex, type: .file)
        if fileAnnotations.isEmpty {
            // Create a file annotation.
            let fileAnnotation = FileAnnotation()
            fileAnnotation.pageIndex = pageIndex
            fileAnnotation.iconName = .graph
            fileAnnotation.color = .blue
            fileAnnotation.boundingBox = CGRect(x: 500, y: 250, width: 32, height: 32)

            // Create an embedded file and add it to the file annotation.
            let embeddedFile = EmbeddedFile(fileURL: embeddedFileURL, fileDescription: "PSPDFKit")
            fileAnnotation.embeddedFile = embeddedFile
            document.add(annotations: [fileAnnotation])
        }
        let pdfController = PDFViewController(document: document)
        return pdfController
    }
}

class AddFreeTextAnnotationProgrammaticallyExample: Example, PDFViewControllerDelegate {

    var controller: PDFViewController?

    override init() {
        super.init()

        title = "Create Text Annotation When Tapping Whitespace"
        category = .annotations
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .annualReport, overrideIfExists: false)
        controller = PDFViewController(document: document)

        // Setup a tap gesture recognizer.
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(tapGestureRecognizerDidChangeState))

        // Make it work simultaneously with all built-in interaction components.
        controller?.interactions.allInteractions.allowSimultaneousRecognition(with: gestureRecognizer)

        // Setup the failure requirement for the annotation selection component.
        if let selectAnnotationComponent = controller?.interactions.selectAnnotation {
            gestureRecognizer.require(toFail: selectAnnotationComponent)
        }

        // Setup the failure requirement for the annotation deselection component.
        if let deselectAnnotationComponent = controller?.interactions.deselectAnnotation {
            gestureRecognizer.require(toFail: deselectAnnotationComponent)
        }

        // Add your gesture recognizer to the document view controller's view.
        controller?.view.addGestureRecognizer(gestureRecognizer)

        return controller
    }

    @objc func tapGestureRecognizerDidChangeState(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended,
              let documentViewController = controller?.documentViewController,
              let pageView = documentViewController.visiblePageView(at: gestureRecognizer.location(in: documentViewController.view)),
              let document = controller?.document,
              let textParser = document.textParserForPage(at: pageView.pageIndex)
        else {
            return
        }

        /*
         We only want to allow taps on whitespace to have an effect, and a touch covers a size. So we
         give the touch a finite size, and see if any of the text blocks on this page intersect.
         If that’s the case, we’re not dealing with whitespace, and therefore should not create a new
         annotation.
         */
        let viewPoint = gestureRecognizer.location(in: pageView)
        let touchSize = CGSize(width: 10, height: 10)
        let touchArea = CGRect(origin: CGPoint(x: viewPoint.x - touchSize.width / 2, y: viewPoint.y - touchSize.height / 2), size: touchSize)

        // Do not forget to convert to PDF coordinates, because that’s where the interesting stuff happens
        let pdfArea = pageView.convert(touchArea, to: pageView.pdfCoordinateSpace)
        if textParser.textBlocks.contains(where: { $0.frame.intersects(pdfArea) }) {
            return
        }

        // Now that we know we aren’t tapping on text, let’s make a new annotation at that point…
        let freeTextAnnotation = FreeTextAnnotation()
        freeTextAnnotation.pageIndex = pageView.pageIndex
        let pdfPoint = pageView.convert(viewPoint, to: pageView.pdfCoordinateSpace)
        freeTextAnnotation.textBoundingBox = CGRect(origin: pdfPoint, size: CGSize(width: 20, height: 20))

        // …style it appropriately and add it to the document
        let styleManager = SDK.shared.styleManager
        styleManager.lastUsedStyle(forKey: .init(tool: .freeText))?.apply(to: freeTextAnnotation)
        document.add(annotations: [freeTextAnnotation])

        /*
         After adding the annotation to the document, select it grab the annotation view, and tell
         it to begin editing, so that the keyboard comes up. The way we set up the PDFViewController,
         we know that the view returned by `annotationView(for:)` is a `FreeTextAnnotationView`.
         Depending on your configuration, this need not be the case.
         */
        pageView.selectedAnnotations = [freeTextAnnotation]
        let annotationView = pageView.annotationView(for: freeTextAnnotation) as! FreeTextAnnotationView
        annotationView.beginEditing()
    }
}
