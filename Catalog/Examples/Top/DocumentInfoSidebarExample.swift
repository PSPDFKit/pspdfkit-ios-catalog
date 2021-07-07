//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

// This example requires the macOS Big Sur SDK.
#if !targetEnvironment(macCatalyst)

class DocumentInfoSidebarExample: Example {

    override init() {
        super.init()

        title = "Document Info Sidebar"
        contentDescription = "Displays the Document Info controllers in the sidebar."
        category = .top
        priority = 4
        wantsModalPresentation = true
        embedModalInNavigationController = false
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        let configuration = PDFConfiguration {
            // Use configuration which makes the `PDFViewController` more in place with the sidebar layout.
            $0.documentLabelEnabled = .NO
            $0.shouldHideNavigationBarWithUserInterface = false
            $0.thumbnailBarMode = .none
            $0.scrollDirection = .vertical
            $0.pageTransition = .scrollContinuous
            $0.signatureStore = KeychainSignatureStore()
        }
        let splitContainerController = SplitContainerViewController(document: document, configuration: configuration)
        splitContainerController.modalPresentationStyle = .fullScreen
        return splitContainerController
    }
}

// MARK: Split Container View Controller

/// Presents a document with a sidebar setup. The sidebar displays the document info,
/// such as the document outline, bookmarks, annotations, info and security options.
private class SplitContainerViewController: UIViewController, ContainerViewControllerDelegate {

    // MARK: Properties

    /// Controller containing the Document Info Sidebar and the Document view.
    private var containedSplitViewController: UISplitViewController

    /// Controller displayed in the secondary content view along side the sidebar.
    var pdfController: SidebarContentPDFViewController

    /// Controller containing all the Document Info controllers.
    var documentInfoContainerController: ContainerViewController

    /// Controller added as the sidebar. Adds `documentInfoContainerController` as a child controller.
    var sidebarContainerController: SidebarControllersContainingViewController

    /// Button displayed in the navigation bar to show/hide the sidebar.
    private lazy var sidebarToggleButton: UIBarButtonItem = {
        let sidebarToggleIconImage = PSPDFKit.SDK.imageNamed("outline")
        let button = UIBarButtonItem(image: sidebarToggleIconImage, style: .plain, target: self, action: #selector(toggleSidebar(_:)))
        button.title = localizedString("Outline")
        return button
    }()

    // MARK: Initialization and setup.

    /// Creates a controller that presents the specified document in a split view controller.
    /// The document is presented in a `PDFViewController` subclass in the secondary content area.
    /// The primary content area (sidebar) is used to display the document info related controllers.
    /// - Parameters:
    ///   - document: Document to be displayed.
    ///   - configuration: Configuration to be used to setup `PDFViewController` displaying the document.
    init(document: Document?, configuration: PDFConfiguration = PDFConfiguration.default()) {
        // Create a `PDFViewController` to display the document using a custom subclass.
        pdfController = SidebarContentPDFViewController(document: document, configuration: configuration)

        // Access the document info controllers created by the document info coordinator of our `PDFViewController` object.
        let docInfoCoordinator = pdfController.documentInfoCoordinator
        documentInfoContainerController = docInfoCoordinator.documentInfoViewController() as! ContainerViewController

        // Create the containing controller of the Document Info views in the sidebar.
        sidebarContainerController = SidebarControllersContainingViewController(childViewController: documentInfoContainerController)

        // Add the primary (sidebar) and secondary (content) controllers to navigation controllers.
        // Use `PDFNavigationController` so that we can take advantage of the key commands setup.
        let sidebarController = PDFNavigationController(rootViewController: sidebarContainerController)
        let contentController = PDFNavigationController(rootViewController: pdfController)

        // Create a `UISplitViewController` with the above controllers.
        var splitController: UISplitViewController
        if #available(iOS 14, *) {
            splitController = UISplitViewController(style: .doubleColumn)

            splitController.setViewController(sidebarController, for: .primary)
            splitController.setViewController(contentController, for: .secondary)
        } else {
            splitController = UISplitViewController()
            splitController.viewControllers = [sidebarController, contentController]

            // We have to set the preferred display mode here because by default if there is enough space
            // split controller will use `.oneBesideSecondary` which we will not be using for the sake of this example.
            // Defaulting to `.oneOverSecondary` covers the sidebar toggle itself which can be confusing,
            // hence we will just stick to having the sidebar hidden for starters.
            splitController.preferredDisplayMode = .secondaryOnly
        }
        containedSplitViewController = splitController

        super.init(nibName: nil, bundle: nil)

        // To handle callbacks for managing presentations and updating of document info views.
        pdfController.splitContainerViewController = self
        documentInfoContainerController.delegate = self

        // Add the split view controller as a child view controller.
        addChild(containedSplitViewController)
        containedSplitViewController.didMove(toParent: self)

        // We want to disable showing the `displayModeButton` so we can use our custom button to toggle sidebar.
        // Disabling gestures also disables showing the `displayModeButton` on the modern iOS 14 API.
        // For consistency we disable gestures on both.
        splitController.presentsWithGesture = false

        // Update `SidebarContentPDFViewController` navigation items.
        // We add our own bar button item to toggle the sidebar to get our desired sidebar behavior.
        pdfController.navigationItem.setLeftBarButtonItems([sidebarToggleButton, pdfController.settingsButtonItem], for: .document, animated: false)

        let doneButton = UIBarButtonItem(title: localizedString("Done"), style: .done, target: self, action: #selector(dismissExample))
        pdfController.navigationItem.setRightBarButtonItems([doneButton, pdfController.thumbnailsButtonItem, pdfController.bookmarkButtonItem, pdfController.annotationButtonItem], for: .document, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the view of the child split view controller to its parent.
        view.addSubview(containedSplitViewController.view)

        // Focus on the document view to enable using keyboard shortcuts to navigate the document.
        focusDocumentView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Update the child view controller's size
        containedSplitViewController.view.frame = view.bounds
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Dismiss the Document Info Controllers if they are still in modal presentation.
        // We have found dismissing the modal here to be a robust way to avoid interfering with the
        // `UISplitViewController` behavior.
        if let presentedNavigationController = pdfController.presentedViewController as? PDFNavigationController,
           presentedNavigationController.visibleViewController == documentInfoContainerController {
            pdfController.dismiss(animated: false, completion: nil)
        }
    }

    /// Dismisses the base controller presented for this example.
    @objc func dismissExample() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: Sidebar Management.

    /// Shows or hides the sidebar based on its current state.
    @objc func toggleSidebar(_ sender: Any?) {
        // Check whether there's enough space for sidebar to expand.
        if !containedSplitViewController.isCollapsed {
            let currentDisplayMode = containedSplitViewController.displayMode

            /// Whether the sidebar is already visible or not.
            let showSidebar = !(currentDisplayMode == .oneOverSecondary || currentDisplayMode == .oneBesideSecondary)

            sidebarContainerController.addContainedViewControllerIfNecessary()

            if #available(iOS 14, *) {
                // We will use the modern API to show/hide the sidebar column (`.primary`).
                if showSidebar {
                    self.containedSplitViewController.show(.primary)
                } else {
                    self.containedSplitViewController.hide(.primary)
                }
            } else {
                // On older versions we will have to use `preferredDisplayMode` to show/hide the sidebar.
                var displayMode = UISplitViewController.DisplayMode.secondaryOnly
                if showSidebar {
                    displayMode = .oneOverSecondary
                }
                // Animate the change since `preferredDisplayMode` is animatable.
                UIView.animate(withDuration: 0.3) {
                    self.containedSplitViewController.preferredDisplayMode = displayMode
                }
            }
        } else {
            // If the sidebar cannot be expanded then that means we are in compact width.
            // So we will have to present the controller presented in the sidebar modally.
            sidebarContainerController.presentContainedViewControllerModally(on: pdfController)
        }
    }

    /// Dismisses the sidebar if it is in `.oneOverSecondary` mode and ensures that the document view content is visible.
    ///
    /// Useful when an interaction occurs in the sidebar controllers and the result of the interaction is displayed in the `PDFViewController`.
    ///
    /// For example: When an annotation is tapped in the annotation list and the `PDFViewController` scrolls to the annotation and selects it.
    func ensureDocumentViewIsShown() {
        if !containedSplitViewController.isCollapsed && containedSplitViewController.displayMode == .oneOverSecondary {
            if #available(iOS 14, *) {
                containedSplitViewController.show(.secondary)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.containedSplitViewController.preferredDisplayMode = .secondaryOnly
                }
            }
        }
    }

    // MARK: Keyboard Shortcuts Support

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands = super.keyCommands ?? []

        // Moves focus to the document view allowing the user to navigate and operate
        // key command shortcuts using the keyboard.
        let documentViewKeyCommand = UIKeyCommand(title: "Document View", action: #selector(focusDocumentView), input: "D", modifierFlags: [.command, .shift], discoverabilityTitle: "Document View")
        commands.append(documentViewKeyCommand)

        let sidebarCommands = createSidebarKeyCommands()
        commands.append(contentsOf: sidebarCommands)

        let toggleSidebarCommand = UIKeyCommand(title: "Toggle Sidebar", action: #selector(toggleSidebar(_:)), input: "L", modifierFlags: [.control, .command], discoverabilityTitle: "Toggle Sidebar")
        commands.append(toggleSidebarCommand)

        return commands
    }

    /// Creates UIKeyCommand to toggle the controllers added to the sidebar.
    func createSidebarKeyCommands() -> [UIKeyCommand] {
        var commands = [UIKeyCommand]()

        for (index, controller) in documentInfoContainerController.viewControllers.enumerated() {
            let input = "\(index + 1)"
            var title = controller.title ?? "Sidebar Segment: \(input)"

            // Annotation toolbar key command also uses the localized "Annotations" string.
            // We change the key command title for the Annotation List in the Document Info.
            if title == localizedString("Annotations") {
                title = "Annotation List"
            }

            // We rely on the `input` string to know which controller should be focused.
            let command = UIKeyCommand(title: title, action: #selector(focusSidebarController(_:)), input: input, modifierFlags: .command, discoverabilityTitle: title)
            commands.append(command)
        }
        return commands
    }

    /// Changes the focus of the keyboard to the presented `PDFViewController` by making it the first responder.
    @objc func focusDocumentView() {
        ensureDocumentViewIsShown()
        pdfController.becomeFirstResponder()
    }

    /// Changes the focus of the keyboard to the corresponding Document Info Controller in the sidebar.
    @objc func focusSidebarController(_ sender: UIKeyCommand) {
        if let input = sender.input, let controllerIndex = UInt(input) {
            // Present the Document Info views if they are not visible.
            if containedSplitViewController.isCollapsed {
                sidebarContainerController.presentContainedViewControllerModally(on: pdfController)
            } else {
                if #available(iOS 14, *) {
                    containedSplitViewController.show(.primary)
                } else {
                    UIView.animate(withDuration: 0.3) {
                        self.containedSplitViewController.preferredDisplayMode = .oneOverSecondary
                    }
                }
            }

            documentInfoContainerController.setVisibleViewControllerIndex(controllerIndex - 1, animated: true)
        }
    }

    // MARK: ContainerviewControllerDelegate

    func containerViewController(_ controller: ContainerViewController, didUpdateSelectedIndex selectedIndex: UInt) {
        // Update the toolbars when the selected tab in the sidebar changes.
        sidebarContainerController.updateNavigationAndToolbars()
    }
}

// MARK: - Custom PDFViewController subclass

/// `PDFViewController` subclass that overrides the annotation, bookmark, outline, and document info controller delegates to
/// inform the container of its split view controller to dismiss the sidebar of the split view controller if necessary.
private class SidebarContentPDFViewController: PDFViewController {

    /// Controller that manages the presenting `UISplitViewController` of this `PDFViewController` subclass.
    weak var splitContainerViewController: SplitContainerViewController?

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        // Only support the top toolbar positions for the annotation and document editor toolbar.
        annotationToolbarController?.annotationToolbar.supportedToolbarPositions = .top
        documentEditorController.toolbarController.documentEditorToolbar.supportedToolbarPositions = .top
    }

    override func outlineController(_ outlineController: OutlineViewController, didTapAt outlineElement: OutlineElement) -> Bool {
        let didProcess = super.outlineController(outlineController, didTapAt: outlineElement)

        splitContainerViewController?.ensureDocumentViewIsShown()

        return didProcess
    }

    override func bookmarkViewController(_ bookmarkController: BookmarkViewController, didSelect bookmark: Bookmark) {
        super.bookmarkViewController(bookmarkController, didSelect: bookmark)

        splitContainerViewController?.ensureDocumentViewIsShown()
    }

    override func annotationTableViewController(_ annotationController: AnnotationTableViewController, didSelect annotation: Annotation) {
        super.annotationTableViewController(annotationController, didSelect: annotation)

        splitContainerViewController?.ensureDocumentViewIsShown()
    }
}

#endif
