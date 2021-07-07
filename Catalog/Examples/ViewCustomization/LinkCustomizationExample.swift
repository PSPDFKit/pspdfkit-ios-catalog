//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class LinkCustomizationExample: Example {

    override init() {
        super.init()

        title = "Link annotation view customization"
        contentDescription = "Shows how to enforce a fixed style for link annotations."
        type = "com.pspdfkit.catalog.playground.swift"
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: AssetName.quickStart)
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
            // swiftlint:disable:next unused_setter_value
            set {}
        }

        override var strokeWidth: CGFloat {
            get { return fixedStrokeWidth }
            // swiftlint:disable:next unused_setter_value
            set {}
        }
    }
}
