//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class FreeFormResizeExample: Example {

    override init() {
        super.init()

        title = "Free Form Image Resize"
        contentDescription = "Disables the forced aspect ratio resizing for image (stamp) annotations."
        category = .annotations
        priority = 500
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: PSCAssetNameJKHF)
        document?.overrideClass(PSPDFStampAnnotation.self, with: FreeFormResizeStampAnnotation.self)
        return PDFViewController(document: document)
    }
}

class FreeFormResizeStampAnnotation: PSPDFStampAnnotation {

    func shouldMaintainAspectRatio() -> Bool {
        return false
    }
}
