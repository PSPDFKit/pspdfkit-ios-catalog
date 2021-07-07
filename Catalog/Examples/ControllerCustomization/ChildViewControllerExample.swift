//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class ChildViewControllerExample: Example {

    override init() {
        super.init()
        title = "View Controller Containment"
        contentDescription = "Shows how to embed a PDFViewController as a child view controller."
        category = .controllerCustomization
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        ParentViewController(document: AssetLoader.document(for: .annualReport))
    }

}

private class ParentViewController: UIViewController, PDFViewControllerDelegate, UIToolbarDelegate {

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

    private lazy var pdfViewController = PDFViewController(document: document, delegate: self) { builder in
        builder.pageTransition = .scrollContinuous
        builder.scrollDirection = .vertical
        builder.isShadowEnabled = false
        builder.shouldHideNavigationBarWithUserInterface = false
    }

    private lazy var toolbar = UIToolbar()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray
        // Set up the view hierarchy.
        view.addSubview(toolbar)
        addChild(pdfViewController)
        view.addSubview(pdfViewController.view)
        pdfViewController.didMove(toParent: self)
        // The delegate is needed to attach the toolbar to the top of the screen.
        // Otherwise, there will be a gap under the status bar.
        toolbar.delegate = self
        toolbar.items = [
            .init(title: "Done", style: .done, target: self, action: #selector(doneBarButtonItemPressed)),
            .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            pdfViewController.outlineButtonItem,
            pdfViewController.annotationButtonItem,
            pdfViewController.bookmarkButtonItem
        ]
        // Lay out the views using Auto Layout.
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        pdfViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            toolbar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            pdfViewController.view.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 44),
            pdfViewController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 44),
            pdfViewController.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -44),
            pdfViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // If the example was invoked from the search, hiding the navigation bar
        // in viewWillAppear won't work. So we do it here again, just in case.
        if navigationController?.navigationBar.isHidden ?? true { return }
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        .topAttached
    }

    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

}
