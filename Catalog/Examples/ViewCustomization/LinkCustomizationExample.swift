//
//  Copyright © 2018-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class LinkCustomizationExample: Example {

    override init() {
        super.init()

        title = "Link annotation view customization"
        contentDescription = "Shows how to enforce a fixed style for link annotations."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: AssetName.welcome)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(LinkAnnotationView.self, with: AlwaysVisibleLinkAnnotationView.self)
        }
        return controller
    }

    /// Always shows a 1pt red border around link annotations.
    class AlwaysVisibleLinkAnnotationView: LinkAnnotationView {

        let fixedBorderColor = UIColor.red
        let fixedStrokeWidth: CGFloat = 1

        // Override properties to enforce the hardcoded style and ignore
        // any values that would have otherwise been obtained from the
        // link annotation.

        override var borderColor: UIColor? {
            get { fixedBorderColor }
            set {}
        }

        override var strokeWidth: CGFloat {
            get { return fixedStrokeWidth }
            set {}
        }
    }
}
