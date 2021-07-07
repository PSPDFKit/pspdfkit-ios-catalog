//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomVerticalAnnotationToolbarExample: Example {
    override init() {
        super.init()
        title = "Custom Vertical Always-Visible Annotation Toolbar"
        contentDescription = "Reimplements a completely custom annotation toolbar"
        category = .viewCustomization
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        let controller = VerticalAnnotationToolbarPDFViewController(document: document) {
            // Remove the long-press annotation menu
            $0.createAnnotationMenuGroups = []
            $0.editableAnnotationTypes = [.ink, .freeText]
        }
        // Remove the default annotation bar button item
        if let items = controller.navigationItem.rightBarButtonItems(for: .document)?
            .filter({ $0 != controller.annotationButtonItem }) {
            controller.navigationItem.setRightBarButtonItems(items, for: .document, animated: false)
        }
        return controller
    }
}

final private class VerticalAnnotationToolbarPDFViewController: PDFViewController {
    var verticalToolbar: CustomVerticalAnnotationToolbar?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the custom toolbar and anchor it on the trailing side of the PDF controller view.
        let verticalToolbar = CustomVerticalAnnotationToolbar(annotationStateManager: annotationStateManager)
        verticalToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(verticalToolbar)

        NSLayoutConstraint.activate([
            verticalToolbar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            verticalToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.verticalToolbar = verticalToolbar
    }

    override func setViewMode(_ viewMode: ViewMode, animated: Bool) {
        super.setViewMode(viewMode, animated: animated)
        // Ensure custom annotation toolbar is hidden when thumbnails are shown
        UIView.animate(withDuration: 0.25, delay: 0, options: .allowUserInteraction) {
            self.verticalToolbar?.alpha = viewMode == .thumbnails ? 0 : 1
        }
    }
}

final private class CustomVerticalAnnotationToolbar: UIView {
    let annotationStateManager: AnnotationStateManager
    var drawButton: UIButton?
    var freeTextButton: UIButton?
    var undoButton: UIButton?
    var redoButton: UIButton?

    required init(annotationStateManager: AnnotationStateManager) {
        self.annotationStateManager = annotationStateManager
        super.init(frame: .zero)

        annotationStateManager.add(self)

        let editableAnnotationTypes = annotationStateManager.pdfController?.configuration.editableAnnotationTypes ?? []
        if editableAnnotationTypes.contains(.ink) {
            drawButton = button(withImageName: "ink", action: #selector(inkButtonPressed))
        }
        if editableAnnotationTypes.contains(.freeText) {
            freeTextButton = button(withImageName: "freetext", action: #selector(freeTextButtonPressed))
        }
        undoButton = button(withImageName: "undo", action: #selector(undoButtonPressed))
        undoButton?.isEnabled = false
        redoButton = button(withImageName: "redo", action: #selector(redoButtonPressed))
        redoButton?.isEnabled = false

        let stackView = UIStackView(arrangedSubviews: [drawButton, freeTextButton, undoButton, redoButton].compactMap({ $0 }))
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        addSubview(stackView)

        let buttonLength: CGFloat = 44

        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: buttonLength),
            stackView.heightAnchor.constraint(equalToConstant: buttonLength * CGFloat(stackView.arrangedSubviews.count)),
            widthAnchor.constraint(equalTo: stackView.widthAnchor),
            heightAnchor.constraint(equalTo: stackView.heightAnchor)
        ])

        backgroundColor = UIColor.psc_systemBackground
    }

    func button(withImageName imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        let image = SDK.imageNamed(imageName)!.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func inkButtonPressed() {
        annotationStateManager.toggleState(.ink)
    }

    @objc func freeTextButtonPressed() {
        annotationStateManager.toggleState(.freeText)
    }

    @objc func undoButtonPressed() {
        undoManager?.undo()
    }

    @objc func redoButtonPressed() {
        undoManager?.redo()
    }
}

extension CustomVerticalAnnotationToolbar: AnnotationStateManagerDelegate {
    static let selectedColor = UIColor.psc_label.withAlphaComponent(0.2)
    static let deselectedColor = UIColor.clear

    func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        drawButton?.backgroundColor = newState == .ink ? CustomVerticalAnnotationToolbar.selectedColor : CustomVerticalAnnotationToolbar.deselectedColor
        freeTextButton?.backgroundColor = newState == .freeText ? CustomVerticalAnnotationToolbar.selectedColor : CustomVerticalAnnotationToolbar.deselectedColor
    }

    func annotationStateManager(_ manager: AnnotationStateManager, didChangeUndoState undoEnabled: Bool, redoState redoEnabled: Bool) {
        undoButton?.isEnabled = undoEnabled
        redoButton?.isEnabled = redoEnabled
    }
}
