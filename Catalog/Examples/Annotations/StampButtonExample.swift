//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCStampButtonExample.m' for the Objective-C version of this example.

class StampButtonExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Stamp Annotation Button"
        contentDescription = "Uses a stamp annotation as button."
        category = .annotations
        priority = 130
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        document.annotationSaveMode = .disabled

        let imageStamp = StampAnnotation()
        imageStamp.image = UIImage(named: "exampleimage.jpg")
        imageStamp.boundingBox = CGRect(x: 100.0, y: 100.0, width: imageStamp.image!.size.width / 4.0, height: imageStamp.image!.size.height / 4.0)

        imageStamp.pageIndex = 0

        // We need to define an action to get a highlight.
        // You can also use an empty script and do custom processing in the didTapOnAnnotation: delegate.
        imageStamp.additionalActions = [.mouseUp: JavaScriptAction(script: "app.alert(\"Hello, it's me. I was wondering...\");")]

        document.add(annotations: [imageStamp])
        let pdfController = PDFViewController(document: document, delegate: self)
        return pdfController
    }

    // MARK: - PDFViewControllerDelegate

    private func pdfViewController(_: PDFViewController, didTapOn annotation: Annotation, annotationPoint: CGPoint, annotationView: AnnotationPresenting, pageView: PDFPageView, viewPoint: CGPoint) -> Bool {
        return false
    }
}
