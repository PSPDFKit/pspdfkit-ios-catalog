//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Instant

/// This example connects to our public PSPDFKit for Web examples server and downloads documents using PSPDFKit Instant.
/// You can then collaboratively annotate these documents using Instant.
/// Each document on the PSPDFKit for Web examples server can be accessed via its URL.
///
/// The example lets you either create a new collaboration group then share the URL,
/// or join an existing collaboration group by entering a URL.
/// To speed this up, the URL can be read from a QR code.
///
/// Other supported clients include:
///
/// - PSPDFKit Instant Live Demo: https://pspdfkit.com/instant/demo/
/// - PSPDFKit for Web examples: https://web-examples.pspdfkit.com
/// - PDF Viewer for iOS and Android: https://pdfviewer.io
/// - PSPDFKit Catalog example app for Android
///
/// As is usually the case with Instant, most of the code here deals with communicating with the
/// particular server backend (our Web examples server in this case), so is not particularly useful
/// as example code. The same applies to the other files in this folder.
///
/// The code actually interacting with the Instant framework API is in `InstantDocumentViewController.swift`.
class InstantExample: Example {

    override init() {
        super.init()

        title = "PSPDFKit Instant"
        contentDescription = "Downloads a document for collaborative editing."
        category = .collaboration
        priority = 1

        if #available(macCatalyst 14, *) {} else {
            targetDevice = []
        }
    }

    weak var presentingViewController: UIViewController?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let presentingViewController = delegate.currentViewController!

        // We store the document info once the session is created.
        // We will try to find the stored info matching the document identifier for this example if available.
        if let docInfoDict = UserDefaults.standard.object(forKey: InstantExampleLastViewedDocumentInfoKey) as? [String: String],
           let lastViewDocumentInfo = InstantDocumentInfo(from: docInfoDict) {
            // Present the InstantViewController directly using the existing document info extracted from the cache.
            presentInstantViewController(for: lastViewDocumentInfo, on: presentingViewController)
        } else {
            presentNewSession(on: presentingViewController)
        }

        // Hold a reference to the presentingViewController to handle authentication challenges.
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
            apiClient.createNewSession(for: InstantDemoDocumentIdentifier) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)

                    switch result {
                    case let .success(documentInfo):
                        self.presentInstantViewController(for: documentInfo, on: viewController)
                    case .failure(.cancelled):
                        break // Do not show the alert if user cancelled the request themselves.
                    case let .failure(otherError):
                        viewController.showAlert(withTitle: "Couldn’t Get Instant Document Info", message: otherError.localizedDescription)
                    }
                }
            }
        }
    }

    private func presentInstantViewController(for instantDocumentInfo: InstantDocumentInfo, on viewController: UIViewController) {
        let instantViewController = InstantDocumentViewController(documentInfo: instantDocumentInfo, lastViewedDocumentInfoKey: InstantExampleLastViewedDocumentInfoKey)
        let navigationController = UINavigationController(rootViewController: instantViewController)
        navigationController.modalPresentationStyle = .fullScreen
        viewController.present(navigationController, animated: true)
    }
}

extension InstantExample: WebExamplesAPIClientDelegate {

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
