//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class AppearanceStreamGeneratorWithCustomDrawingExample: Example {

    override init() {
        super.init()

        title = "Appearance Stream Generator with a custom drawing block"
        contentDescription = "Shows how to add additional custom drawing for a vector stamp annotation."
        category = .annotations
        priority = 70
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled
        let logoURL = AssetLoader.assetURL(for: "PSPDFKit Logo.pdf")
        let pageIndex: PageIndex = 0

        // Add a stamp annotation.
        let stampAnnotation = StampAnnotation()
        stampAnnotation.boundingBox = CGRect(x: 180.0, y: 150.0, width: 444.0, height: 500.0)
        stampAnnotation.color = UIColor(red: 0, green: 100 / 255, blue: 0, alpha: 1)
        stampAnnotation.fillColor = UIColor.clear
        stampAnnotation.alpha = 0.5
        stampAnnotation.lineWidth = 5
        stampAnnotation.pageIndex = pageIndex

        // Create the appearance stream generator and setup its drawing block.
        let appearanceStreamGenerator = FileAppearanceStreamGenerator(fileURL: logoURL)
        appearanceStreamGenerator.drawingBlock = { context in
            // Custom drawing: Draw a green square border around the stamp.
            let box = stampAnnotation.boundingBox
            let color = stampAnnotation.color
            context.saveGState()
            guard let colorRef = color?.cgColor else {
                return
            }
            context.setStrokeColor(colorRef)
            context.stroke(box)
            context.setFillColor(colorRef)

            let lineWidth = stampAnnotation.lineWidth
            let strokeRect: CGRect = box.insetBy(dx: lineWidth / 2.0, dy: lineWidth / 2.0)
            let path = CGPath(rect: strokeRect, transform: nil)
            context.setLineWidth(lineWidth)
            context.setAlpha(stampAnnotation.alpha)
            context.addPath(path)
            context.drawPath(using: .stroke)
            context.restoreGState()
        }

        // Set the annotation's appearance stream generator.
        stampAnnotation.appearanceStreamGenerator = appearanceStreamGenerator
        document.add(annotations: [stampAnnotation])

        let controller = PDFViewController(document: document)
        return controller
    }
}
