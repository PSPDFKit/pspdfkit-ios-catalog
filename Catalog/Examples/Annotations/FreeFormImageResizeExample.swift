//
//  Copyright © 2017-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class FreeFormResizeExample: Example {

    override init() {
        super.init()

        title = "Free Form Image Resize"
        contentDescription = "Disables the forced aspect ratio resizing for image (stamp) annotations."
        category = .annotations
        priority = 500
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        document.overrideClass(StampAnnotation.self, with: FreeFormResizeStampAnnotation.self)
        return PDFViewController(document: document)
    }
}

private class FreeFormResizeStampAnnotation: StampAnnotation {

    override var shouldMaintainAspectRatio: Bool {
        false
    }

    override class var supportsSecureCoding: Bool {
        true
    }
}
