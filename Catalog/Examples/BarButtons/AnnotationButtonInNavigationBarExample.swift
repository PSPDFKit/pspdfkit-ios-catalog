//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class AnnotationButtonInNavigationBarExample: Example {

    override init() {
        super.init()
        title = "Annotation Buttons in Navigation Bar"
        contentDescription = "Shows how to add annotation buttons to the navigation bar and update their state."
        category = .barButtons
        priority = 80
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        CustomPDFViewController(document: AssetLoader.document(for: .JKHF))
    }

}

private class CustomPDFViewController: PDFViewController, AnnotationStateManagerDelegate {

    override init(document: Document?, configuration: PDFConfiguration?) {
        super.init(document: document, configuration: configuration)
        annotationStateManager.add(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var inkBarButtonItem = UIBarButtonItem(
        image: PSPDFKit.SDK.imageNamed("ink"),
        style: .plain,
        target: self,
        action: #selector(inkBarButtonItemPressed)
    )

    private lazy var eraserBarButtonItem = UIBarButtonItem(
        image: PSPDFKit.SDK.imageNamed("eraser"),
        style: .plain,
        target: self,
        action: #selector(eraserBarButtonItemPressed)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButtonItems([annotationButtonItem, eraserBarButtonItem, inkBarButtonItem], for: .document, animated: false)
    }

    @objc private func inkBarButtonItemPressed(_ sender: UIBarButtonItem) {
        annotationStateManager.toggleState(.ink, variant: .inkPen)
    }

    @objc private func eraserBarButtonItemPressed(_ sender: UIBarButtonItem) {
        annotationStateManager.toggleState(.eraser)
    }

    func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        // Set the buttons to "x" once the corresponding tool is activated.
        inkBarButtonItem.image = (newState == .ink && newVariant == .inkPen) ? PSPDFKit.SDK.imageNamed("x") : PSPDFKit.SDK.imageNamed("ink")
        eraserBarButtonItem.image = (newState == .eraser) ? PSPDFKit.SDK.imageNamed("x") : PSPDFKit.SDK.imageNamed("eraser")
    }

}
