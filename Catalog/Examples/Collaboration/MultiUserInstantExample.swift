//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Instant
import WebKit

class MultiUserInstantExample: Example {

    override init() {
        super.init()

        title = "Multi-User Instant Example"
        contentDescription = "Shows multiple instances of an Instant document for collaborative editing."
        category = .collaboration
        priority = 2

        if #available(macCatalyst 14, *) {
            // Make example only available on the iPad.
            targetDevice = .pad
        } else {
            targetDevice = []
        }
        wantsModalPresentation = true
        embedModalInNavigationController = false
    }

    weak var presentingViewController: UIViewController?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let presentingViewController = delegate.currentViewController!

        // We store the document info once the session is created.
        // We will try to find the stored info matching the document identifier for this example if available.
        if let docInfoDict = UserDefaults.standard.object(forKey: MultiUserInstantExampleLastViewedDocumentInfoKey) as? [String: String],
           let lastViewDocumentInfo = InstantDocumentInfo(from: docInfoDict) {
            // Present the InstantViewController directly using the existing document info extracted from the cache.
            presentInstantViewController(for: lastViewDocumentInfo, on: presentingViewController)
        } else {
            presentNewSession(on: presentingViewController)
        }

        // Hold a reference to the presentingViewController to handle URLActionChallenge.
        self.presentingViewController = presentingViewController

        return nil
    }

    /// Connects to the Example API Client to get the document info for the current example
    /// and then displays that document in a `InstantViewController`.
    func presentNewSession(on viewController: UIViewController) {
        // Create a `WebExamplesAPIClient` instance using the URL of the client server
        // that has the list of documents the particular user can access.
        //
        // `WebExamplesAPIClient` can make calls to the server to get the document info required
        // to connect to a PSPDFKit Server.
        //
        // For the purpose of this example we are using the PSPDFKit for Web Catalog server.
        // In your app, this should be replaced by the URL of your that is interacting with the PSPDFKit Server.
        // See https://pspdfkit.com/guides/ios/current/pspdfkit-instant/overview/ for more details.
        let apiClient = WebExamplesAPIClient(baseURL: InstantWebExamplesServerURL, delegate: self)

        let progressHUDItem = StatusHUDItem.indeterminateProgress(withText: "Creating")
        progressHUDItem.setHUDStyle(.black)

        progressHUDItem.push(animated: true, on: viewController.view.window) {
            // Asking the PSPDFKit for Web Catalog example server to create a new session
            // for the given user and the specified document identifier.
            // It should ideally provide a signed JWT (and the PSPDFKit Server if not already available)
            // that can be used by the `InstantClient` to access and download the document for iOS.
            apiClient.createNewSession(for: InstantMarketingDepartmentScheduleDocumentIdentifier) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)

                    switch result {
                    case let .success(documentInfo):
                        self.presentInstantViewController(for: documentInfo, on: viewController)
                    case let .failure(error):
                        viewController.showAlert(withTitle: "Couldn’t Get Instant Document Info", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func presentInstantViewController(for instantDocumentInfo: InstantDocumentInfo, on viewController: UIViewController) {
        let instantViewController = MultiUserContainerViewController(documentInfo: instantDocumentInfo)
        instantViewController.modalPresentationStyle = .fullScreen
        viewController.present(instantViewController, animated: true)
    }

}

// MARK: Split Container View Controller

/// Presents a multi-user setup for an Instant document where the iOS Instant SDK is used one side
/// to display and edit the document acting as one user along with a Web View on the other side
/// showing the same document acting as another user.
private class MultiUserContainerViewController: UIViewController, UISplitViewControllerDelegate, PDFViewControllerDelegate {

    private var containedSplitViewController: UISplitViewController

    init(documentInfo: InstantDocumentInfo) {

        instantController = ContainedInstantDocumentViewController(documentInfo: documentInfo, lastViewedDocumentInfoKey: MultiUserInstantExampleLastViewedDocumentInfoKey)
        instantController.updateConfiguration {
            $0.useParentNavigationBar = true
            $0.shouldHideNavigationBarWithUserInterface = false
        }

        webviewContainerController = InstantExampleWebViewContainerController(documentInfo: documentInfo)

        instantController.title = "iOS SDK User"
        webviewContainerController.title = "Web SDK User"

        let primaryColumnContainer = SidebarControllersContainingViewController(childViewController: instantController)
        let primaryColumnNavVC = PDFNavigationController(rootViewController: primaryColumnContainer)
        let secondaryColumnNavVC = PDFNavigationController(rootViewController: webviewContainerController)

        // Create a `UISplitViewController` with the above controllers.
        var splitController: UISplitViewController
        if #available(iOS 14, *) {
            splitController = UISplitViewController(style: .doubleColumn)

            splitController.setViewController(primaryColumnNavVC, for: .primary)
            splitController.setViewController(secondaryColumnNavVC, for: .secondary)
        } else {
            splitController = UISplitViewController()
            splitController.viewControllers = [primaryColumnNavVC, secondaryColumnNavVC]
        }

        // We want to show split the display area equally between the two controllers.
        splitController.preferredDisplayMode = .oneBesideSecondary
        splitController.minimumPrimaryColumnWidth = 200
        splitController.maximumPrimaryColumnWidth = 1000
        splitController.preferredPrimaryColumnWidthFraction = 0.5

        // Disabled because we do not want to show the `displayModeButton` show since iOS 14.
        splitController.presentsWithGesture = false
        containedSplitViewController = splitController

        super.init(nibName: nil, bundle: nil)

        instantController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var instantController: InstantDocumentViewController

    var webviewContainerController: InstantExampleWebViewContainerController

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

}

private class ContainedInstantDocumentViewController: InstantDocumentViewController {

    /// Whether automatic syncing of the Instant document is enabled or not.
    var isSyncEnabled = true

    lazy var syncButtonItem = UIBarButtonItem(title: "Disable Sync", style: .plain, target: self, action: #selector(toggleSyncing(_:)))

    override init(documentInfo: InstantDocumentInfo, lastViewedDocumentInfoKey: String? = nil) {
        super.init(documentInfo: documentInfo, lastViewedDocumentInfoKey: lastViewedDocumentInfoKey)

        // We do not want to allow changing the document editing sessions at all for this example.
        collaborationOptionsConfiguration = .init(documentIdentifierForNewSession: documentInfo.documentId, allowJoiningExistingSessions: false, allowCreatingNewSessions: false)

        navigationItem.setLeftBarButtonItems([exampleCloseButtonItem, syncButtonItem], for: .document, animated: false)

        annotationToolbarController?.annotationToolbar.supportedToolbarPositions = .right
        annotationToolbarController?.annotationToolbar.toolbarPosition = .right
    }

    /// Toggles auto-syncing state of the Instant document.
    @objc func toggleSyncing(_ sender: UIBarButtonItem) {
        do {
            if isSyncEnabled {
                try InstantDocumentManager.shared.disableSync(for: documentInfo)
                sender.title = "Enable Sync"
                isSyncEnabled = false
            } else {
                try InstantDocumentManager.shared.enableSync(for: documentInfo)
                sender.title = "Disable Sync"
                isSyncEnabled = true
            }
        } catch {
            showAlert(withTitle: "Couldn't Disable Instant Syncing", message: error.localizedDescription)
        }
    }
}

// MARK: - Web View Container

/// Presents a Web View displaying the Instant Document using the sharing URL.
private class InstantExampleWebViewContainerController: UIViewController, WKUIDelegate {

    /// Username that will be sent to the web page displaying the Instant Document when asked for the user name.
    lazy var webCommentUserName = "Web User"

    var webView: WKWebView

    var documentInfo: InstantDocumentInfo

    init(documentInfo: InstantDocumentInfo) {
        self.documentInfo = documentInfo
        webView = WKWebView()
        super.init(nibName: nil, bundle: nil)
        webView.uiDelegate = self
    }

    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Use the Instant document's sharing URL to display the document in the web view.
        let url = documentInfo.url
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        completionHandler(webCommentUserName)
    }

}

extension MultiUserInstantExample: WebExamplesAPIClientDelegate {

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
