//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

class ButtonImageGalleryExample: Example, PDFViewControllerDelegate {
    override init() {
        super.init()
            title = "Galleries with button activation"
            contentDescription = "Buttons that show/hide gallery or videos."
            category = .multimedia
            priority = 51
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.temporaryDocument(with: "")
        document.annotationSaveMode = .disabled

        do {
            let title = FreeTextAnnotation(contents: "Galleries with button activation")
            title.fontSize = 20
            title.boundingBox = CGRect(x: 20.0, y: 750.0, width: 300.0, height: 40.0)
            document.add(annotations: [title], options: nil)
        }

        do {
            let text = FreeTextAnnotation(contents: "Gallery that opens inline:\n\n[Action.Option.buttonKey: NSNumber(value: true)]")
            text.fontSize = 15
            text.boundingBox = CGRect(x: 20.0, y: 600.0, width: 350.0, height: 60.0)

            // Setting the button option to yes will show the default button.
            let url = URL(string: "pspdfkit://localhost/Bundle/sample.gallery")!
            let galleryAction = URLAction(url: url, options: [
                Action.Option.buttonKey: true
            ])
            let galleryAnnotation = LinkAnnotation(action: galleryAction)
            galleryAnnotation.boundingBox = CGRect(x: 80.0, y: 550.0, width: 300.0, height: 200.0)
            document.add(annotations: [text, galleryAnnotation], options: nil)
        }

        do {
            let text = FreeTextAnnotation(contents: "Gallery that opens inline with a custom button image:\n\n[Action.Option.buttonKey: \"pspdfkit://localhost/Bundle/eye.png\"]")
            text.fontSize = 15
            text.boundingBox = CGRect(x: 20.0, y: 450.0, width: 450.0, height: 60.0)

            // Setting the button option to an URL will load this URL. The URL can be local or remote. Use pspdfkit://localhost for local URLs.
            // For remote URLs, use something such as:
            // [Action.Option.buttonKey: "https://www.dropbox.com/s/8diroz5npb3eciy/webimage2%402x.png?raw=1"]
            let url = URL(string: "pspdfkit://localhost/Bundle/sample.gallery")!
            let action = URLAction(url: url, options: [
                Action.Option.buttonKey: "pspdfkit://localhost/Bundle/eye.png"
            ])

            let galleryAnnotation = LinkAnnotation(action: action)
            galleryAnnotation.boundingBox = CGRect(x: 260.0, y: 400.0, width: 300.0, height: 200.0)
            document.add(annotations: [text, galleryAnnotation], options: nil)
        }

        do {
            let text = FreeTextAnnotation(contents: "Opens Gallery in popover:")
            text.fontSize = 15.0
            text.boundingBox = CGRect(x: 20.0, y: 300.0, width: 200.0, height: 30.0)

            // An empty text annotation which helps locate the position of the invisible link annotation.
            let background = FreeTextAnnotation()
            background.fillColor = UIColor.red
            background.boundingBox = CGRect(x: 225.0, y: 305.0, width: 30.0, height: 30.0)

            // The link annotation that we create here does not have a visible appearance.
            let galleryAnnotation = LinkAnnotation(url: URL(string: "pspdfkit://[popover:1,size:50x50]localhost/Bundle/sample.gallery")!)
            galleryAnnotation.boundingBox = CGRect(x: 225.0, y: 305.0, width: 30.0, height: 30.0)
            document.add(annotations: [text, background, galleryAnnotation], options: nil)
        }

        do {
            let text = FreeTextAnnotation(contents: "Link that opens modally:\n\nAction.Option.buttonKey: NSNumber(value: true),\nAction.Option.modalKey: NSNumber(value: true),\nAction.Option.sizeKey: NSNumber(cgSize: CGSize(width: 550.0, height: 550.0))")
            text.fontSize = 15.0
            text.boundingBox = CGRect(x: 20.0, y: 80.0, width: 600.0, height: 120.0)

            let url = URL(string: "pspdfkit://www.apple.com/ipad/")!
            let action = URLAction(url: url, options: [
                Action.Option.buttonKey: true,
                Action.Option.modalKey: true,
                Action.Option.sizeKey: CGSize(width: 550.0, height: 550.0)
            ])
            let webAnnotation = LinkAnnotation(action: action)
            webAnnotation.boundingBox = CGRect(x: 205.0, y: 175.0, width: 30.0, height: 30.0)
            document.add(annotations: [text, webAnnotation], options: nil)
        }

        let pdfController = PDFViewController(document: document) { builder in
            // Disable free text editing here as we use them as labels.
            builder.editableAnnotationTypes = nil
        }
        return pdfController
    }
}
