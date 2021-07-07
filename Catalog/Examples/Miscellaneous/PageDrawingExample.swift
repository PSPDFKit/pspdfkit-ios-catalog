//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class PageDrawingExample: Example {

    override init() {
        super.init()
            title = "Draw Overlay Text On All Pages"
            contentDescription = "Shows how to add custom drawing rendering on pages."
            category = .miscellaneous
            priority = 501
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        document.title = "Draw overlay text on all pages"
        let pdfController = PDFViewController(document: document)

        let drawBlock: PDFRenderDrawBlock = { context, _, cropBox, _ in
            // Careful, this code is executed on background threads. Only use thread-safe drawing methods.
            // Set up the text and it's drawing attributes.
            let overlayText = "Example Overlay"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24.0),
                .foregroundColor: UIColor.blue
            ]

            // Set text drawing mode (fill).
            context.setTextDrawingMode(.fill)

            // Calculate the font box to center the text on the page.
            let boundingBox = overlayText.size(withAttributes: attributes)
            let point = CGPoint(x: round((cropBox.size.width - boundingBox.width) / 2), y: round((cropBox.size.height - boundingBox.height) / 2))

            // Finally draw the text.
            overlayText.draw(at: point, withAttributes: attributes)
        }

        document.updateRenderOptions(for: .all) { options in
            options.drawBlock = drawBlock
        }

        return pdfController
    }
}
