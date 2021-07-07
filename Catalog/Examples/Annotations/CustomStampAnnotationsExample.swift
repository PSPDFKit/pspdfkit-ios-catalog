//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCCustomStampAnnotationsExample.m' for the Objective-C version of this example.

class CustomStampAnnotationsExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Custom stamp annotations"
        contentDescription = "Customizes the default set of stamps in the PSPDFStampViewController."
        category = .annotations
        priority = 200
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        var defaultStamps = [StampAnnotation]()
        for stampTitle in ["Great!", "Stamp", "Like"] {
            let stamp = StampAnnotation(title: stampTitle)
            stamp.boundingBox = CGRect(x: 0, y: 0, width: 200, height: 70)
            defaultStamps.append(stamp)
        }
        // Careful with memory - you don't wanna add large images here.
        let imageStamp = StampAnnotation()
        imageStamp.image = UIImage(named: "exampleimage.jpg")
        imageStamp.boundingBox = CGRect(x: 0, y: 0, width: (imageStamp.image?.size.width)! / 4, height: (imageStamp.image?.size.height)! / 4)
        defaultStamps.append(imageStamp)

        let logoURL = AssetLoader.assetURL(for: "PSPDFKit Logo.pdf")

        let vectorStamp = StampAnnotation()
        vectorStamp.boundingBox = CGRect(x: 0, y: 0, width: 200, height: 200)
        vectorStamp.appearanceStreamGenerator = FileAppearanceStreamGenerator(fileURL: logoURL)
        defaultStamps.append(vectorStamp)
        StampViewController.defaultStampAnnotations = defaultStamps

        let document = AssetLoader.document(for: .JKHF)

        // `CustomPDFViewController` is used as it resets the above set `defaultStampAnnotations`.
        let pdfController = CustomPDFViewController(document: document, delegate: self)
        pdfController.navigationItem.rightBarButtonItems = [pdfController.annotationButtonItem]

        return pdfController
    }

    // MARK: - PDFViewControllerDelegate

    func pdfViewController(_ pdfController: PDFViewController, shouldShow controller: UIViewController, options: [String: Any]? = nil, animated: Bool) -> Bool {
        let stampController = PSPDFChildViewControllerForClass(controller, StampViewController.self) as? StampViewController
        stampController?.customStampEnabled = false
        stampController?.dateStampsEnabled = false

        return true
    }
}

private class CustomPDFViewController: PDFViewController {

    deinit {
        // Reset the default stamp annotations so that the other examples can use the default stamps.
        StampViewController.defaultStampAnnotations = nil
    }

}
