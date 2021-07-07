//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomLinkProtocolExample: Example {

    override init() {
        super.init()

        title = "Custom Link Protocol"
        contentDescription = "Uses a custom pspdfcatalog:// link protocol."
        category = .annotations
        priority = 800
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.temporaryDocument(with: "Test PDF for custom Protocols")
        document.annotationSaveMode = .disabled

        // Add link
        // By default, PSPDFKit would ask if you want to leave the app when an external URL is detected.
        // We skip this question if the protocol is defined within our own app.
        let link = PSPDFLinkAnnotation(url: URL(string: "pspdfcatalog://this-is-a-test-link")!)
        let pageSize = document.pageInfoForPage(at: 0)!.size
        let size = CGSize(width: 400, height: 300)
        link.boundingBox = CGRect(x: (pageSize.width - size.width) / 2, y: (pageSize.height - size.height) / 2, width: size.width, height: size.height)
        document.add([link])

        let pdfController = PDFViewController(document: document)
        return pdfController
    }
}
