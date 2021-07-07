//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomLinkBorderColorExample: Example {

    override init() {
        super.init()

        title = "Customize the Border Color for Links"
        contentDescription = "Shows how to set a red border color for links."
        category = .subclassing
        priority = 170
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(LinkAnnotationView.self, with: CustomBorderColorLinkAnnotationView.self)
        }

        // Go to a page with a link.
        controller.pageIndex = 8
        return controller
    }
}

private class CustomBorderColorLinkAnnotationView: LinkAnnotationView {

    override var strokeWidth: CGFloat {
        get { return 1 }
        // swiftlint:disable:next unused_setter_value
        set {}
    }

    override var borderColor: UIColor? {
        get { return UIColor.red.withAlphaComponent(0.5) }
        // swiftlint:disable:next unused_setter_value
        set {}
    }
}
