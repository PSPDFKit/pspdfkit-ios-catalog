//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class ManualToolbarSetupExample: Example {

    override init() {
        super.init()
        title = "Manual annotation toolbar setup and management"
        contentDescription = "Flexible toolbar handling without UINavigationController or PSPDFAnnotationBarButtonItem."
        category = .barButtons
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        let controller = ManualToolbarSetupViewController(document: document)
        delegate.currentViewController?.present(controller, animated: true)
        // Present modally, so we can more easily configure it to have a different style.
        return nil
    }
}

private class ManualToolbarSetupViewController: UIViewController, UIToolbarDelegate, FlexibleToolbarContainerDelegate {

    private let pdfController: PDFViewController
    private lazy var customToolbar = UIToolbar(frame: CGRect(x: 0, y: 20, width: view.bounds.width, height: 44))
    private var flexibleToolbarContainer: FlexibleToolbarContainer?

    // MARK: Lifecycle

    init(document: Document) {
        // Add PDFViewController as a child view controller.
        pdfController = PDFViewController(document: document) {
            $0.userInterfaceViewMode = .never
            $0.backgroundColor = UIColor.psc_systemBackground
        }

        // Those need to be nilled out if you use the barButton items (e.g., annotationButtonItem) externally!
        pdfController.navigationItem.leftBarButtonItems = nil
        pdfController.navigationItem.rightBarButtonItems = nil

        super.init(nibName: nil, bundle: nil)

        addChild(pdfController)
        pdfController.didMove(toParent: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.psc_systemBackground

        view.addSubview(pdfController.view)

        // As an example, here we're not using the UINavigationController but instead a custom UIToolbar.
        // Note that if you're going that way, you'll lose some features that PSPDFKit provides, like dynamic toolbar updating or accessibility.
        customToolbar.delegate = self
        customToolbar.autoresizingMask = .flexibleWidth

        // Configure the toolbar items
        var toolbarItems = [UIBarButtonItem]()
        customToolbar.isTranslucent = false
        toolbarItems.append(contentsOf: [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed)), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)])

        // Normally we would just use the annotationButtonItem and let it do all the toolbar setup and management for us.
        // Here, however we'll show how one could manually configure and show the annotation toolbar without using
        // PSPDFAnnotationBarButtonItem. Note that PSPDFAnnotationBarButtonItem handles quite a few more
        // cases and should in general be preferred to this simple toolbar setup.

        // It's still a good idea to check if annotations are available
        if pdfController.document?.canSaveAnnotations ?? false {
            toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(toggleToolbar)))
        }
        customToolbar.items = toolbarItems
        view.addSubview(customToolbar)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    // MARK: Annotation toolbar

    @objc private func toggleToolbar(_ sender: Any) {
        if let flexibleToolbarContainer = flexibleToolbarContainer {
            flexibleToolbarContainer.hideAndRemove(animated: true) { _ in }
            return
        }
        let manager = pdfController.annotationStateManager
        let toolbar = AnnotationToolbar(annotationStateManager: manager)
        toolbar.matchUIBarAppearance(customToolbar)
        // (optional)
        let container = FlexibleToolbarContainer(frame: view.bounds)
        container.flexibleToolbar = toolbar
        container.overlaidBar = customToolbar
        container.containerDelegate = self
        view.addSubview(container)
        flexibleToolbarContainer = container
        container.show(animated: true)
    }

    // MARK: FlexibleToolbarContainerDelegate

    func flexibleToolbarContainerDidHide(_ container: FlexibleToolbarContainer) {
        flexibleToolbarContainer = nil
    }

    func flexibleToolbarContainerContentRect(_ container: FlexibleToolbarContainer) -> CGRect {
        pdfController.view.frame
    }

    // MARK: Layout

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Position the pdfController content below the toolbar
        var frame: CGRect = view.bounds
        frame.origin.y = customToolbar.frame.maxY
        frame.size.height -= frame.origin.y
        pdfController.view.frame = frame
    }

    // MARK: Public

    var document: Document? {
        get {
            pdfController.document
        }
        set {
            pdfController.document = newValue
        }
    }

    // MARK: Private

    @objc private func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }

    // MARK: UIBarPositioningDelegate
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
