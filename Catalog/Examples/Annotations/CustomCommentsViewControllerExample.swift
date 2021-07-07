//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomCommentsViewControllerExample: Example {

    override init() {
        super.init()

        title = "Custom Comments (Notes) UI"
        contentDescription = "Replaces PSPDFNoteAnnotationViewController with a custom view controller."
        category = .annotations
        priority = 72
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(PDFPageView.self, with: CustomPageView.self)
        }
        return controller
    }
}

private class CustomPageView: PDFPageView {
    override func showNoteController(for annotation: Annotation, animated: Bool) {
        let commentsViewController = CustomCommentsViewController()
        let navigationController = UINavigationController(rootViewController: commentsViewController)
        presentationContext?.actionDelegate.present(navigationController, options: nil, animated: animated, sender: nil, completion: nil)
    }
}

private class CustomCommentsViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss(sender:)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.psc_systemBackground
    }

    @objc func dismiss(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
