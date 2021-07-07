//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class AnnotateImagesExample: Example {

    override init() {
        super.init()

        title = "Annotate an Image"
        contentDescription = "Annotate an image using PSPDFImageDocument."
        category = .annotations
        priority = 100
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let sourceURL = AssetLoader.assetURL(for: "PSPDFKit Image Example.jpg")
        let writeableImageURL = sourceURL.copyToDocumentDirectory()

        // `PSPDFImageDocument` uses `flattenAndEmbed` as the default save mode. This allows the annotations added to the image to remain editable when it is reopened.
        let document = ImageDocument(imageURL: writeableImageURL)

        // We apply a special configuration that configures the PDF controller with settings that
        // work well for displaying images.
        let controller = PDFViewController(document: document, configuration: PDFConfiguration.image)

        // Not all stock button items make sense for images, so be sure to customize the UI.
        let rightItems = [controller.annotationButtonItem, controller.activityButtonItem, controller.searchButtonItem]
        let leftItems = [controller.outlineButtonItem, controller.brightnessButtonItem]
        controller.navigationItem.setRightBarButtonItems(rightItems, for: .document, animated: false)
        controller.navigationItem.setLeftBarButtonItems(leftItems, for: .document, animated: false)

        controller.navigationItem.leftItemsSupplementBackButton = true

        return controller
    }
}
