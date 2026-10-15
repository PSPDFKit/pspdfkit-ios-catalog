//
//  Copyright © 2018-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CustomCommentsViewControllerExample: Example {

    override init() {
        super.init()

        title = "Custom Comments (Notes) UI"
        contentDescription = "Replaces PSPDFNoteAnnotationViewController with a custom view controller."
        category = .annotations
        priority = 72
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .welcome)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(PDFPageView.self, with: CustomPageView.self)
        }
        return controller
    }
}

private class CustomPageView: PDFPageView {
    override func presentComments(for annotation: Annotation, options: [PresentationOption: Any] = [:], animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
        let commentsViewController = CustomCommentsViewController()
        let navigationController = UINavigationController(rootViewController: commentsViewController)
        presentationContext?.actionDelegate.present(navigationController, options: options, animated: animated, sender: nil, completion: completion)
        return navigationController
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
