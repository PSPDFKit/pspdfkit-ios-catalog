//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Instant
import PSPDFKit
import PSPDFKitUI

class InstantLayersExample: Example {

    override init() {
        super.init()

        title = "Instant Layers Example"
        contentDescription = "Shows how to display different sets of annotations on a document using Instant Layers."
        category = .collaboration
        priority = 3

        wantsModalPresentation = true
        embedModalInNavigationController = false
    }

    weak var presentingViewController: UIViewController?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let currentViewController = delegate.currentViewController!
        presentNewSession(on: currentViewController)
        presentingViewController = currentViewController

        return nil
    }

    /// Connects to the Example API Client to get the document info for the current example
    /// and then displays that document in a `InstantViewController`.
    func presentNewSession(on viewController: UIViewController) {
        // URL of the client server (your server) that has the list of documents the particular user can access.
        // See https://www.nutrient.io/guides/ios/instant-synchronization/ for more details.
        let apiClient = WebExamplesAPIClient(delegate: self)

        let progressHUDItem = StatusHUDItem.indeterminateProgress(withText: "Creating")
        progressHUDItem.setHUDStyle(.black)

        // Append UUID to the layer names to create unique layers for each session.
        let sessionUUID = UUID().uuidString
        let layerNames = ["Review-1", "Review-2", "Review-3"].map { $0.appending(sessionUUID) }

        progressHUDItem.push(animated: true, on: viewController.view.window) {
            // Ask your server to create a new session for the given user and the specified document identifier.
            // It should ideally provide a signed JWT (and the Nutrient Document Engine if not already available)
            // that can be used by the `InstantClient` to access and download the document for iOS.
            apiClient.createNewSession(with: layerNames) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)

                    switch result {
                    case let .success(documentLayers):
                        // Process the instant document layers to remove the appended unique identifier
                        // from the layer name so the name is a human readable label.
                        var processedLayers = [String: InstantDocumentInfo]()
                        for (key, value) in documentLayers {
                            let processedKey = key.replacingOccurrences(of: sessionUUID, with: "")
                            processedLayers[processedKey] = value
                        }
                        self.presentInstantViewController(for: processedLayers, on: viewController)
                    case let .failure(error):
                        viewController.showAlert(withTitle: "Couldn’t Get Instant Document Info", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func presentInstantViewController(for documentLayers: [String: InstantDocumentInfo], on viewController: UIViewController) {
        let instantViewController = MultipleInstantLayersContainerViewController(documentLayers: documentLayers)
        instantViewController.modalPresentationStyle = .fullScreen
        viewController.present(instantViewController, animated: true)
    }

}

private class MultipleInstantLayersContainerViewController: UIViewController, UISplitViewControllerDelegate {

    // MARK: Properties

    /// Controller containing the Instant Layers listing and the Document view.
    private var containedSplitViewController: UISplitViewController

    /// Controller displaying the Instant Document in the content view of the split view controller.
    var instantController: ContainedInstantDocumentViewController

    /// Controller displaying the list of available Instant Layers in the sidebar of the split view controller.
    var instantLayersListController: InstantLayersListViewController

    /// Controller added as the sidebar. Adds `instantLayersListController` as a child controller.
    var sidebarContainerController: SidebarControllersContainingViewController

    /// Button displayed in the navigation bar to show/hide the sidebar.
    private lazy var sidebarToggleButton: UIBarButtonItem = {
        let sidebarToggleIconImage = PSPDFKit.SDK.imageNamed("document_outline")
        let button = UIBarButtonItem(image: sidebarToggleIconImage, style: .plain, target: self, action: #selector(togglesSidebar(_:)))
        button.title = "Document Layers"
        return button
    }()

    init(documentLayers: [String: InstantDocumentInfo]) {
        instantLayersListController = InstantLayersListViewController(documentLayers: documentLayers)
        instantLayersListController.title = "Layers"

        // Upon initialization `InstantLayersListViewController` defaults to the first layer.
        // This is why we use `selectedLayerName` to access the first layer to display.
        let selectedLayerName = instantLayersListController.selectedLayerName
        instantController = ContainedInstantDocumentViewController(documentInfo: documentLayers[selectedLayerName]!)
        instantController.title = "Instant Layers Example"

        // `instantLayersListController` instance needs to know if a new session was started by
        // the `instantController` so that it can add the new session layer to the listing.
        instantController.documentInfoSessionDelegate = instantLayersListController

        sidebarContainerController = SidebarControllersContainingViewController(childViewController: instantLayersListController)

        let sidebarController = PDFNavigationController(rootViewController: sidebarContainerController)
        let contentController = PDFNavigationController(rootViewController: instantController)

        // Create a `UISplitViewController` with the above controllers.
        let splitController = UISplitViewController(style: .doubleColumn)
        splitController.setViewController(sidebarController, for: .primary)
        splitController.setViewController(contentController, for: .secondary)

        splitController.preferredDisplayMode = .oneBesideSecondary
        containedSplitViewController = splitController

        // We want to disable showing the `displayModeButton` so we can use our custom button to toggle sidebar.
        // Disabling gestures also disables showing the `displayModeButton`.
        // For consistency we disable gestures on both.
#if !os(visionOS)
        splitController.presentsWithGesture = false
#endif

        super.init(nibName: nil, bundle: nil)

        // Assign the `instantController` as the delegate of the `InstantLayersListViewController`
        // so the `instantController` instance can update the document layer it is presenting.
        instantLayersListController.delegate = self

        // We add our own bar button item to toggle the sidebar to get our desired sidebar behavior.
        instantController.navigationItem.setLeftBarButtonItems([sidebarToggleButton], for: .document, animated: false)
        instantController.navigationItem.setRightBarButtonItems([instantController.exampleCloseButtonItem, instantController.annotationButtonItem, instantController.collaborateButtonItem], for: .document, animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(containedSplitViewController)
        view.addSubview(containedSplitViewController.view)
        containedSplitViewController.didMove(toParent: self)

        containedSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containedSplitViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            containedSplitViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            containedSplitViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            containedSplitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Shows or hides the sidebar based on its current state.
    @objc func togglesSidebar(_ sender: Any?) {
        // Check whether there's enough space for sidebar to expand.
        if !containedSplitViewController.isCollapsed {
            let currentDisplayMode = containedSplitViewController.displayMode

            /// Whether the sidebar is already visible or not.
            let showSidebar: Bool
#if os(visionOS)
            showSidebar = currentDisplayMode != .oneBesideSecondary
#else
            showSidebar = !(currentDisplayMode == .oneOverSecondary || currentDisplayMode == .oneBesideSecondary)
#endif

            sidebarContainerController.addContainedViewControllerIfNecessary()

            // We will use the modern API to show/hide the sidebar column (`.primary`).
            if showSidebar {
                self.containedSplitViewController.show(.primary)
            } else {
                self.containedSplitViewController.hide(.primary)
            }
        } else {
            // If the sidebar cannot be expanded then that means we are in compact width.
            // So we will have to present the controller presented in the sidebar modally.
            sidebarContainerController.presentContainedViewControllerModally(on: instantController)
        }
    }

    func ensureDocumentViewIsShown() {
        let isInOneOverSecondary: Bool
#if os(visionOS)
        isInOneOverSecondary = false
#else
        isInOneOverSecondary = containedSplitViewController.displayMode == .oneOverSecondary
#endif
        if !containedSplitViewController.isCollapsed && isInOneOverSecondary {
            containedSplitViewController.show(.secondary)
        }
    }

}

extension MultipleInstantLayersContainerViewController: InstantLayersListViewControllerDelegate {

    func instantLayersListController(_ instantLayersListController: InstantLayersListViewController, didSelectLayer selectedLayer: InstantDocumentInfo, selectedLayerIndex: UInt) {
        // Change the document displayed by the instant controller to correspond to the corresponding
        // document of the selected layer name in the Layers list.
        instantController.changeVisibleDocument(to: selectedLayer, clearLocalStorage: false)
        instantController.displayingLayerIndex = selectedLayerIndex
        ensureDocumentViewIsShown()
    }
}

/// `InstantDocumentViewController` subclass that preloads the document with annotations
/// upon download.
private class ContainedInstantDocumentViewController: InstantDocumentViewController {

    override init(documentInfo: InstantDocumentInfo, lastViewedDocumentInfoKey: String? = nil) {
        super.init(documentInfo: documentInfo, lastViewedDocumentInfoKey: lastViewedDocumentInfoKey)

        // We don't want to allow creating new sessions for this document and the example.
        collaborationOptionsConfiguration = InstantCollaborationOptionsViewControllerConfiguration(
            documentIdentifierForNewSession: documentInfo.documentId,
            allowJoiningExistingSessions: true,
            allowCreatingNewSessions: false,
            allowsOpeningArbitraryDocuments: false
        )
    }

    /// Index of the Selected Layer corresponding to the `InstantLayersListViewController` instance.
    var displayingLayerIndex: UInt = 0

    /// Backing store of the indexes of the document layers that have had annotation preloaded.
    var preloadedLayerIndexes: Set<UInt> = []

    override func didFinishDownload(for documentInfo: InstantDocumentInfo) {
        // Add some default annotations to distinguish between the different layers.
        // We add these annotations when the downloading of the document has been completed.
        if !preloadedLayerIndexes.contains(displayingLayerIndex) {
            let preloadedAnnotations = InstantLayersExampleAnnotationsHelper.annotationsForLayer(at: displayingLayerIndex)
            document?.add(annotations: preloadedAnnotations)
            preloadedLayerIndexes.insert(displayingLayerIndex)
        }
    }

}

private protocol InstantLayersListViewControllerDelegate: AnyObject {

    /// `InstantDocumentInfo` of the layer selected from the list of layers presented by the `InstantLayersListViewController`.
    func instantLayersListController(_ instantLayersListController: InstantLayersListViewController, didSelectLayer selectedLayer: InstantDocumentInfo, selectedLayerIndex: UInt)
}

/// Displays a list of the available layers for the ongoing session shown in the sidebar for the
/// Instant Layers Example.
/// The list allows selecting between the available layers and passing on that information to its delegate.
/// In this example, the delegate is the `InstantViewController` subclass that will update the document it is
/// editing to the document selected in the list.
private class InstantLayersListViewController: UITableViewController, InstantDocumentViewControllerDelegate {

    /// Backing store of `InstantDocumentInfo` for the document layers to be listed stored against
    /// the layer name as their key.
    private(set) var documentLayers: [String: InstantDocumentInfo] {
        didSet {
            layerNames = Array(documentLayers.keys.sorted())
        }
    }

    /// Layer names listed by the controller.
    /// Convenience access for the sorted keys of `documentLayers`.
    private(set) var layerNames: [String]

    /// Index of the selected layer name.
    private(set) var selectedLayerIndex = 0

    var selectedLayerName: String {
        layerNames[selectedLayerIndex]
    }

    weak var delegate: InstantLayersListViewControllerDelegate?

    init(documentLayers: [String: InstantDocumentInfo]) {
        self.documentLayers = documentLayers
        self.layerNames = Array(documentLayers.keys.sorted())

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let cellIdentifier = "InstantLayerCellIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let indexPath = IndexPath(row: selectedLayerIndex, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.deselectRow(at: (IndexPath(row: selectedLayerIndex, section: 0)), animated: false)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        layerNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = .systemBlue
        cell.textLabel?.text = layerNames[indexPath.row]
        cell.textLabel?.highlightedTextColor = .white
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLayerIndex = indexPath.row
        let selectedLayerName = layerNames[selectedLayerIndex]
        let selectedLayer = documentLayers[selectedLayerName]!
        delegate?.instantLayersListController(self, didSelectLayer: selectedLayer, selectedLayerIndex: UInt(selectedLayerIndex))

        // Dismiss the list if it is presented as a modal individually i.e not in a `splitViewController`.
        if splitViewController == nil {
            dismiss(animated: true)
        }
    }

    func instantDocumentController(_ instantDocumentController: InstantDocumentViewController, didCreateNewSession documentInfo: InstantDocumentInfo) {
        let layerCount = layerNames.count
        let newLayerName = "Review-\(layerCount + 1)"
        documentLayers[newLayerName] = documentInfo
        tableView.reloadData()

        selectedLayerIndex = layerCount
        let indexPath = IndexPath(row: selectedLayerIndex, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
}

extension InstantLayersExample: WebExamplesAPIClientDelegate {

    func examplesAPIClient(_ apiClient: WebExamplesAPIClient, didReceiveBasicAuthenticationChallenge challenge: URLAuthenticationChallenge, completion: @escaping (URLCredential?) -> Void) {
        presentingViewController?.presentBasicAuthPrompt(for: challenge) { username, password in
            guard let user = username,
                  let pass = password else {
                completion(nil)
                return
            }

            let urlCredential = URLCredential(user: user, password: pass, persistence: .permanent)
            completion(urlCredential)
        }
    }

}

// MARK: - Preloading Annotations Helper

/// A wrapper for the helper functions which create annotations
/// that are used by the InstantLayerExample to preload the different
/// layers with annotations.
private struct InstantLayersExampleAnnotationsHelper {

    static func annotationsForLayer(at index: UInt) -> [Annotation] {
        switch index {
        case 0:
            return annotationsForLayer1()
        case 1:
            return annotationsForLayer2()
        case 2:
            return annotationsForLayer3()
        default:
            return annotationsForLayer1()
        }
    }

    private static func annotationsForLayer1() -> [Annotation] {
        var annotations = [Annotation]()

        let draftStamp = StampAnnotation(stampType: .draft)
        draftStamp.boundingBox = CGRect(x: 1065, y: 421, width: 90, height: 21)
        annotations.append(draftStamp)

        let noteAnnotation = NoteAnnotation(contents: "I like the choice of bio degradable lighting.")
        noteAnnotation.color = .red
        noteAnnotation.boundingBox = CGRect(x: 240, y: 620, width: 32, height: 32)
        annotations.append(noteAnnotation)

        let freeTextAnnotation = FreeTextAnnotation(contents: "We need lighting in the hallway as well")
        freeTextAnnotation.color = .red
        freeTextAnnotation.boundingBox = CGRect(x: 592, y: 495, width: 97, height: 32)
        freeTextAnnotation.fontSize = 9
        annotations.append(freeTextAnnotation)

        let lineAnnotation = LineAnnotation(point1: CGPoint(x: 596, y: 499), point2: CGPoint(x: 500, y: 416))
        lineAnnotation.lineEnd2 = .closedArrow
        lineAnnotation.fillColor = UIColor(red: 0.87, green: 0.27, blue: 0.30, alpha: 1)
        lineAnnotation.color = UIColor(red: 0.87, green: 0.27, blue: 0.30, alpha: 1)
        annotations.append(lineAnnotation)

        return annotations
    }

    private static func annotationsForLayer2() -> [Annotation] {
        var annotations = [Annotation]()

        let needsRevisionStamp = StampAnnotation(title: "Needs Revision")
        needsRevisionStamp.boundingBox = CGRect(x: 1065, y: 421, width: 90, height: 21)
        annotations.append(needsRevisionStamp)

        let lightingsComment = FreeTextAnnotation(contents: "We can add more lights here.")
        lightingsComment.boundingBox = CGRect(x: 506, y: 246, width: 128, height: 15)
        lightingsComment.borderColor = .blue
        lightingsComment.fontSize = 9.5
        annotations.append(lightingsComment)

        let squigglyAnnotation = SquareAnnotation()
        squigglyAnnotation.borderEffect = .cloudy
        squigglyAnnotation.borderColor = .blue
        squigglyAnnotation.borderEffectIntensity = 1
        squigglyAnnotation.lineWidth = 1
        squigglyAnnotation.boundingBox = CGRect(x: 485, y: 240, width: 162, height: 54)
        annotations.append(squigglyAnnotation)

        return annotations
    }

    private static func annotationsForLayer3() -> [Annotation] {
        var annotations = [Annotation]()

        let approvedStamp = StampAnnotation(stampType: .approved)
        approvedStamp.boundingBox = CGRect(x: 748, y: 286, width: 275, height: 95)
        annotations.append(approvedStamp)

        let freeText = FreeTextAnnotation(contents: "We are good to go!")
        freeText.boundingBox = CGRect(x: 755, y: 144, width: 275, height: 98)
        freeText.borderColor = .green
        freeText.fontSize = 40
        annotations.append(freeText)

        return annotations
    }
}
