//
//  Copyright © 2019-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Instant
import PSPDFKit
import PSPDFKitUI

protocol InstantDocumentViewControllerDelegate: AnyObject {

    /// Called by the `InstantDocumentViewController` whenever it creates or joins a new session using the Collaborate menu option.
    func instantDocumentController(_ instantDocumentController: InstantDocumentViewController, didCreateNewSession documentInfo: InstantDocumentInfo)
}

/// Shows a document managed by Instant along with options to
/// extend the collaboration or create a new collaboration session.
public class InstantDocumentViewController: InstantViewController, InstantDocumentManagerDocumentObserver {

    private(set) var documentInfo: InstantDocumentInfo {
        didSet {
            updateLastViewedInstantDocumentInfo()
        }
    }

#if os(visionOS)
    lazy var collaborateOrnamentItem = OrnamentItem(kind: .button(configuration: .init(title: "Collaborate", image: UIImage(systemName: "person.2.fill"), action: { [weak self] anchorView in
        self?.showCollaborationOptions(anchorView)
    })))

    lazy var exampleTitleOrnamentItem = OrnamentItem(kind: .title(provider: { [weak self] in self?.title }))

    lazy var dismissOrnamentItem = OrnamentItem(kind: .button(configuration: .init(title: "Close", image: UIImage(systemName: "chevron.backward"), action: { [weak self] _ in
        self?.dismissExample()
    })))
#endif

    lazy var collaborateButtonItem = {
        // On macOS 13 and 14, showing a popover from this bar button item with a title and no image will raise an exception:
        // “UIPopoverPresentationController (...) should have a non-nil sourceView or barButtonItem set before the presentation occurs.”
        // even when the source properties are set. Therefore make sure an image is used.
        let item = UIBarButtonItem(image: UIImage(systemName: "person.2.fill"), style: .plain, target: self, action: #selector(showCollaborationOptions(_:)))
        // Also set the title for accessibility.
        item.title = "Collaborate"
        return item
    }()

    lazy var exampleCloseButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissExample))

    /// String to be used as the key against which the `InstantDocumentInfo` of the last viewed document
    /// should be stored in the User Defaults.
    let lastViewedDocumentInfoKey: String?

    lazy var collaborationOptionsConfiguration: InstantCollaborationOptionsViewControllerConfiguration = .init(
        documentIdentifierForNewSession: documentInfo.documentId,
        allowJoiningExistingSessions: true,
        allowCreatingNewSessions: true,
        allowsOpeningArbitraryDocuments: true
    )

    weak var documentInfoSessionDelegate: InstantDocumentViewControllerDelegate?

    public override class var defaultConfiguration: PDFConfiguration {
        super.defaultConfiguration.configurationUpdated {
            $0.pageTransition = .scrollContinuous
            $0.scrollDirection = .vertical
            $0.documentLabelEnabled = .NO
            $0.allowToolbarTitleChange = false

            // The Instant Comment tool is disabled by default. If your server license includes it, you need to
            // explicitly add the identifier to the editable annotation types to display the tools to create new
            // Instant Comments.
            // Our example server has this license flag, so we want to show the tools for all Instant related examples.
            $0.editableAnnotationTypes?.insert(.instantCommentMarker)

            #if os(visionOS)
            $0.thumbnailBarMode = .none
            #endif
        }
    }

    /// Displays an Instant document with option to create new or join existing collaboration sessions.
    /// - Parameters:
    ///   - document: Instant Document to display.
    ///   - documentInfo: Instant Document info provided by the Nutrient Web SDK Catalog server backend.
    public init(documentInfo: InstantDocumentInfo, lastViewedDocumentInfoKey: String? = nil) {
        // Store document info for sharing later.
        self.documentInfo = documentInfo
        self.lastViewedDocumentInfoKey = lastViewedDocumentInfoKey

        // We access the document for the given `documentInfo` using the `InstantDocumentManager`
        // in `viewDidLoad`.
        super.init(document: nil, configuration: Self.defaultConfiguration)

        #if os(visionOS)
        setMainToolbarOrnamentItems([dismissOrnamentItem, exampleTitleOrnamentItem, annotationToolsOrnamentItem, collaborateOrnamentItem], for: .document)
        #else
        let barButtonItems = [collaborateButtonItem, annotationButtonItem]
        navigationItem.setRightBarButtonItems(barButtonItems, for: .document, animated: false)
        #endif

        navigationItem.closeBarButtonItem = exampleCloseButtonItem
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        do {
            // Use `InstantDocumentManager.shared` to access the `Document` instance for this example.
            let document = try InstantDocumentManager.shared.beginModifyingDocument(documentInfo, observer: self)
            self.document = document

            updateLastViewedInstantDocumentInfo()
        } catch let error as InstantError where error.code == InstantError.invalidJWT {
            // This error is recieved when the `jwt` provided by the `InstantDocumentInfo` to access the document is invalid.
            // Please check the JWT provided by your backend and try again.
            // See `InstantError.invalidJWT` for more details.
            self.overlayViewController?.setControllerState(.error, error: error, animated: true)
        } catch {
            self.overlayViewController?.setControllerState(.error, error: error, animated: true)
        }
    }

    @objc private func dismissExample() {
        if let _ = presentedViewController {
            // Dismiss the modally presented view controller if any and then return.
            dismiss(animated: true)
            return
        }
        if document != nil {
            // If we do not have a `document` set then that means there is no need to ask
            // the `InstantDocumentManager` to stop tracking the document backed by documentInfo.
            InstantDocumentManager.shared.endModifyingDocument(documentInfo)
        }
        self.presentingViewController?.dismiss(animated: true)
    }

    @objc private func showCollaborationOptions(_ sender: AnyObject?) {
        let instantCollabViewController = InstantCollaborationOptionsViewController(documentInfo: documentInfo, configuration: collaborationOptionsConfiguration, sender: sender)
        instantCollabViewController.delegate = self
        instantCollabViewController.modalPresentationStyle = .popover
        present(instantCollabViewController, options: [.closeButton: true], animated: true, sender: sender, completion: nil)
    }

    func updateLastViewedInstantDocumentInfo() {
        if let userDefaultsKey = lastViewedDocumentInfoKey,
           // We are being restrictive and only caching last viewed document if it matches the original opened document.
           documentInfo.documentId == collaborationOptionsConfiguration.documentIdentifierForNewSession {
            UserDefaults.standard.set(documentInfo.toDictionary(), forKey: userDefaultsKey)
        }
    }

    func changeVisibleDocument(to instantDocumentInfo: InstantDocumentInfo, clearLocalStorage: Bool = true) {
        do {
            // Mark the currently open document as no longer being modified.
            InstantDocumentManager.shared.endModifyingDocument(documentInfo)

            if clearLocalStorage {
                // Clear the local storage for the old document.
                try InstantDocumentManager.shared.clearLocalStorage(for: documentInfo)
            }

            let modifiableDocument = try InstantDocumentManager.shared.beginModifyingDocument(instantDocumentInfo, observer: self)
            // Set the document on the `PSPDFInstantViewController` (the superclass) so it can show the download progress, and then show the document.
            document = modifiableDocument
            reloadData()

            // Update the Document Info to that of the new document.
            documentInfo = instantDocumentInfo
        } catch {
            self.showAlert(withTitle: "Error Creating New Session", message: error.localizedDescription)
        }
    }

    // MARK: - InstantDocumentManagerDocumentObserver Implementation

    func didFinishDownload(for documentInfo: InstantDocumentInfo) {
        print("Document has finished downloading.")
    }

    func didFailAuthentication(for documentInfo: InstantDocumentInfo) {
        showAlertOnMainQueue(alertTitle: "Instant Document Authentication Failed", message: "Please verify if the given JWT for the document is still valid and that you still have access to the document.")
    }

    func didFailReauthentication(for documentInfo: InstantDocumentInfo, error: Error) {
        showAlertOnMainQueue(alertTitle: "Instant Document Re-authentication Failed", message: error.localizedDescription)
    }

    func didFailSyncing(for documentInfo: InstantDocumentInfo, reason: String) {
        showAlertOnMainQueue(alertTitle: "Instant Sync Failed", message: reason)
    }

    func didFailDownload(for documentInfo: InstantDocumentInfo, error: Error) {
        showAlertOnMainQueue(alertTitle: "Instant Document Download Failed", message: error.localizedDescription)
    }

    /// Shows an alert with the given title and the message asynchronously on the Main Queue.
    /// Used for `InstantDocumentManagerDocumentObserver` callbacks as they are called on a background thread.
    private func showAlertOnMainQueue(alertTitle: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(withTitle: alertTitle, message: message)
        }
    }
}

extension InstantDocumentViewController: InstantCollaborationOptionsViewControllerDelegate {

    func instantCollaborationController(_ instantCollaborationController: InstantCollaborationOptionsViewController, didCreateNewSession documentInfo: InstantDocumentInfo) {
        dismiss(animated: true)
        documentInfoSessionDelegate?.instantDocumentController(self, didCreateNewSession: documentInfo)
        changeVisibleDocument(to: documentInfo)
    }
}
