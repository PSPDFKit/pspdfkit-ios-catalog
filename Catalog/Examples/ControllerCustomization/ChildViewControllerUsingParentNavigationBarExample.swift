//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class ChildViewControllerUsingParentNavigationBarExample: Example {

    override init() {
        super.init()
        title = "View Controller Containment, Using Parent Navigation Bar"
        contentDescription = "Shows how to embed a PDFViewController as a child view controller and let it use its parent's navigation bar."
        category = .controllerCustomization
        priority = 33
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        ParentViewController(document: AssetLoader.document(for: .annualReport))
    }

}

private class ParentViewController: UIViewController {

    init(document: Document?) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var document: Document? {
        didSet {
            guard oldValue !== document else { return }
            pdfViewController.document = document
        }
    }

    private lazy var pdfViewController = PDFViewController(document: document) { builder in
        builder.useParentNavigationBar = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable the large title because it looks weird.
        navigationItem.largeTitleDisplayMode = .never
        // Set up the view hierarhcy.
        addChild(pdfViewController)
        view.addSubview(pdfViewController.view)
        pdfViewController.didMove(toParent: self)
        // Lay out the views using Auto Layout.
        pdfViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pdfViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            pdfViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            pdfViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

}
