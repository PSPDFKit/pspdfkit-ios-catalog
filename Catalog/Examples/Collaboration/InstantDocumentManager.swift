//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Instant

/// This is used for managing and keeping track of all the `Document` instances that are editable
/// and being used by the Instant examples.
/// The primary reason behind introducing this is to have only one `InstantClient` instance per PSPDFKit Server.
class InstantDocumentManager: NSObject, InstantClientDelegate {

    static let shared = InstantDocumentManager()

    private override init() {
        super.init()
    }

    override var description: String {
        "<\(type(of: self)) \(String(format: "%p", self)), trackedDocuments: \(trackedDocuments), instantClients: \(instantClients)>"
    }

    /// Documents being modified at the moment.
    private var trackedDocuments = Set<ManagedDocument>()

    /// Lock used for modifying `trackedDocuments`.
    private var trackedDocumentsLock = NSRecursiveLock()

    /// `InstantClient` instances used to connect to the various PSPDFKit Server instances.
    /// Each PSPDFKit Server should have only one `InstantClient` instance in use.
    private var instantClients = Set<InstantClient>()

    // MARK: - ManagedDocument

    /// Used by the `InstantDocumentManager` while interacting with `InstantClient` and `InstantDocumentDescriptor`
    /// API to create editable and read-only document instaces.
    private class ManagedDocument: NSObject {
        let serverURL: URL
        var JWT: String
        let documentIdentifier: String
        let encodedDocumentId: String
        let url: URL

        var isInEditMode: Bool = false
        let client: InstantClient
        let descriptor: InstantDocumentDescriptor
        weak var observer: InstantDocumentManagerDocumentObserver?

        init(documentIdentifier: String, encodedDocumentId: String, url: URL, serverURL: URL, JWT: String, observer: InstantDocumentManagerDocumentObserver? = nil, client: InstantClient, descriptor: InstantDocumentDescriptor) {
            self.documentIdentifier = documentIdentifier
            self.encodedDocumentId = encodedDocumentId
            self.serverURL = serverURL
            self.JWT = JWT
            self.url = url
            self.client = client
            self.descriptor = descriptor
            self.observer = observer
        }

        override func isEqual(_ object: Any?) -> Bool {
            if let rhs = object as? ManagedDocument {
                return self.JWT == rhs.JWT && self.serverURL == rhs.serverURL && self.documentIdentifier == rhs.documentIdentifier && self.url == rhs.url
            }
            return false
        }

        override var hash: Int {
            var hasher = Hasher()
            hasher.combine(JWT)
            hasher.combine(serverURL)
            hasher.combine(documentIdentifier)
            hasher.combine(url)
            return hasher.finalize()
        }

        override var description: String {
            "\(super.description), documentIdentifier:\(documentIdentifier), ur: \(url), JWT:\(JWT), serverURL:\(serverURL)."
        }
    }

    /// Returns a `Document` instance that can be used to display in a `InstantViewController` to allow
    /// document editing.
    /// Call `endModifyingDocument(_:)` once you have finished editing the document
    /// to allow other `InstantViewController` instances to display/edit the document.
    ///
    /// - Parameters:
    ///   - documentInfo: Document info to use to download an editable document from a PSPDFKit Server.
    ///   - observer: An object that should be notified of the completion/errors occurred while accessing the document
    ///   form the PSPDFKit Server using `InstantClient`.
    /// - Throws: `InstantDocumentManagerError.documentInUse` if the editable instance of the document is already
    /// in use.
    /// - Returns: `Document` instance that can be displayed in a `InstantViewController` for editing purpose.
    func beginModifyingDocument(_ documentInfo: InstantDocumentInfo, observer: InstantDocumentManagerDocumentObserver? = nil) throws -> Document {
        if existingDocument(matching: documentInfo) != nil {
            throw InstantDocumentManagerError.documentInUse
        }

        let client = try instantClient(for: documentInfo)
        let descriptor = try documentDescriptor(for: documentInfo)

        let trackedDocument = ManagedDocument(documentIdentifier: documentInfo.documentId, encodedDocumentId: documentInfo.encodedDocumentId, url: documentInfo.url, serverURL: documentInfo.serverURL, JWT: documentInfo.jwt, observer: observer, client: client, descriptor: descriptor)
        requestDocumentDownload(for: trackedDocument, using: descriptor)

        let writableDoc = descriptor.editableDocument

        trackedDocument.isInEditMode = true
        _ = trackedDocumentsLock.withLock {
            trackedDocuments.insert(trackedDocument)
        }
        return writableDoc
    }

    /// Stops tracking the document and makes it available for editing by other instances.
    /// - Parameter documentInfo: `InstantDocumentInfo` of the document that no longer should be tracked.
    /// - Throws: `InstantDocumentManagerError.unableToEndModifyingDocument` if removing the document from
    /// the tracking list was unsuccessful. Use `isModifyingDocument(_:)` instead to check if document is being tracked.
    func endModifyingDocument(_ documentInfo: InstantDocumentInfo) {
        let documentToRemove = existingDocument(matching: documentInfo)

        // It is a programmer error if the `InstantDocumentManager` is asked to stop tracking
        // a document that is not being tracked.
        assert(documentToRemove != nil, "Document should have been tracked if the InstantDocumentManager is asked to stop tracking it.")
        assert(documentToRemove?.isInEditMode == true, "Document should have been in edit mode if it is being tracked.")

        documentToRemove?.isInEditMode = false
        trackedDocumentsLock.withLock {
            assert(trackedDocuments.remove(documentToRemove!) != nil, "Document should have been removed from the tracked documents' list.")
        }
    }

    /// Whether the given Instant Document info's editable instance of a `Document` is in use by an instance.
    /// Returns the `ManagedDocument` if the document is in being modified and nil otherwise.
    private func existingDocument(matching documentInfo: InstantDocumentInfo) -> ManagedDocument? {
        trackedDocumentsLock.withLock {
            if let trackedDoc = trackedDocuments.first(where: { $0.encodedDocumentId == documentInfo.encodedDocumentId && $0.serverURL == documentInfo.serverURL }) {
                assert(trackedDoc.isInEditMode, "Document should have been in edit mode if it is being tracked.")
                return trackedDoc
            }
            return nil
       }
    }

    /// Asks the `InstantDocumentDescriptor` to download the document from the relevant `InstantClient`.
    /// Will try to reuathenticate using the `ManagedDocument.JWT` of the provided
    /// document if the document is already downloaded otherwise informs the `observer` with the error.
    private func requestDocumentDownload(for managedDocument: ManagedDocument, using descriptor: InstantDocumentDescriptor) {
        // Return early if downloaded in progress.
        guard descriptor.downloadProgress == nil else { return }
        let documentInfo = InstantDocumentInfo(serverURL: managedDocument.serverURL, url: managedDocument.url, jwt: managedDocument.JWT, documentId: managedDocument.documentIdentifier, encodedDocumentId: managedDocument.encodedDocumentId)
        do {
            if descriptor.isDownloaded {
                // Since the document is already available on disk, we just have to re-authenticate the document
                // using the token (JWT).
                descriptor.reauthenticate(withJWT: managedDocument.JWT)
            } else {
                try descriptor.download(usingJWT: managedDocument.JWT)
            }
        } catch {
            managedDocument.observer?.didFailDownload(for: documentInfo, error: error)
        }
    }

    /// Returns corresponding tracked document for the given `InstantClient` and `InstantDocumentDescriptor`.
    /// Used in the `InstantClientDelegate` implementation to access the observer and notify.
    private func trackedDocument(for instantClient: InstantClient, documentDescriptor: InstantDocumentDescriptor) -> ManagedDocument? {
        trackedDocumentsLock.withLock {
            trackedDocuments.first {
                $0.descriptor === documentDescriptor &&
                    $0.client === instantClient
            }
       }
    }

    /// Use to access the corresponding `InstantClient` for the given `InstantDocumentInfo`.
    /// Creates a new instance if one doesn't already exists.
    private func instantClient(for documentInfo: InstantDocumentInfo) throws -> InstantClient {
        try trackedDocumentsLock.withLock {
            if let client = instantClients.first(where: { $0.serverURL == documentInfo.serverURL }) {
                return client
            }
            let newClient = try InstantClient(serverURL: documentInfo.serverURL)
            newClient.delegate = self
            instantClients.insert(newClient)
            return newClient
       }
    }

    /// Use to access the `InstantDocumentDescriptor` for the given `InstantDocumentInfo`
    /// from its corresponding `InstantClient`.
    private func documentDescriptor(for documentInfo: InstantDocumentInfo) throws -> InstantDocumentDescriptor {
        let client = try instantClient(for: documentInfo)
        let descriptor = try client.documentDescriptor(forJWT: documentInfo.jwt)
        return descriptor
    }

    /// Clears the local storage of the given document `InstantDocumentInfo`.
    func clearLocalStorage(for documentInfo: InstantDocumentInfo) throws {
        if existingDocument(matching: documentInfo) != nil {
            throw InstantDocumentManagerError.documentInUse
        }
        let descriptor = try documentDescriptor(for: documentInfo)
        try descriptor.removeLocalStorage()
    }

    /// Clears the local storage completely by clearing the local storage of all the `InstantClient`
    /// instances created in order to access a document.
    func clearAllLocalStorage() throws {
        try trackedDocumentsLock.withLock {
            let clients = instantClients
            for client in clients {
                try client.removeLocalStorage()
            }
        }
    }

    /// Enables auto-syncing of the document backed by the given `InstantDocumentInfo`.
    /// Also, a sync call is also made to sync any unsaved changes.
    func enableSync(for documentInfo: InstantDocumentInfo) throws {
        let descriptor = try documentDescriptor(for: documentInfo)

        // Enable auto-syncing by changing the delay to the default value of 1.
        descriptor.delayForSyncingLocalChanges = 1

        // Call `sync` explicitly to instantaneously start syncing the changes that might
        // have been made when auto-syncing was disabled. Otherwise, those changes will not
        // be synced until another change is made.
        descriptor.sync()
    }

    /// Cancels any ongoing syncing request and disables auto-syncing of the document backed by the given `InstantDocumentInfo`.
    func disableSync(for documentInfo: InstantDocumentInfo) throws {
        let descriptor = try documentDescriptor(for: documentInfo)

        // Manually stop any ongoing syncing request since we are about to disable syncing.
        descriptor.stopSyncing(true)

        // Disable auto-syncing by changing the delay to `InstantSyncingLocalChangesDisabled`.
        descriptor.delayForSyncingLocalChanges = InstantSyncingLocalChangesDisabled
    }

    // MARK: InstantClientDelegate

    func instantClient(_ instantClient: InstantClient, didFinishDownloadFor documentDescriptor: InstantDocumentDescriptor) {
        if let trackedDocument = trackedDocument(for: instantClient, documentDescriptor: documentDescriptor),
           let observer = trackedDocument.observer {
            let documentInfo = InstantDocumentInfo(serverURL: trackedDocument.serverURL, url: trackedDocument.url, jwt: trackedDocument.JWT, documentId: trackedDocument.documentIdentifier, encodedDocumentId: trackedDocument.encodedDocumentId)
            // We forward this call to the observer so that the observer can carry out any additional setup if it wants to.
            // For ex: In `InstantLayersExample`, `didFinishDownload(for:)` is implemented to add
            // a set of default annotations to the layer.
            observer.didFinishDownload(for: documentInfo)
        }
    }

    func instantClient(_ instantClient: InstantClient, documentDescriptor: InstantDocumentDescriptor, didFailDownloadWithError error: Error) {
        if let trackedDocument = trackedDocument(for: instantClient, documentDescriptor: documentDescriptor),
           let observer = trackedDocument.observer {
            let documentInfo = InstantDocumentInfo(serverURL: trackedDocument.serverURL, url: trackedDocument.url, jwt: trackedDocument.JWT, documentId: trackedDocument.documentIdentifier, encodedDocumentId: trackedDocument.encodedDocumentId)
            // The document download from the PSPDFKit Server can fail and in that case you should
            // check for the failure reason and retry the download accordingly with appropriate information.
            // See `InstantError` for a list of possible erros.
            // We do not forward download failure in case it was a result of a user cancellation.
            if (error as NSError).code != NSUserCancelledError {
                observer.didFailDownload(for: documentInfo, error: error)
            }
        }
    }

    func instantClient(_ instantClient: InstantClient, didFailAuthenticationFor documentDescriptor: InstantDocumentDescriptor) {
        if let trackedDocument = trackedDocument(for: instantClient, documentDescriptor: documentDescriptor),
           let observer = trackedDocument.observer {
            let documentInfo = InstantDocumentInfo(serverURL: trackedDocument.serverURL, url: trackedDocument.url, jwt: trackedDocument.JWT, documentId: trackedDocument.documentIdentifier, encodedDocumentId: trackedDocument.encodedDocumentId)
            // The JWT is used to authenticated while downloading the document using `InstantDocumentDescriptor.download(usingJWT:)`
            // in `InstantDocumentManager.beginModifyingDocument(_:observer:)` and this `InstantClientDelegate` method is
            // called if the authentication fails or if the JWT has expired.
            // You should try get a new JWT from your backend and then used that to reauthenticate by calling `InstantDocumentDescriptor.reauthenticate(withJWT:)`.
            // The reauthentcation can also fail if the user no longer has access to the document. In that case,
            // the document should be removed from the local storage using the `InstantDocumentDescriptor.removeLocalStorage()` API.
            observer.didFailAuthentication(for: documentInfo)
        }
    }

    func instantClient(_ instantClient: InstantClient, documentDescriptor: InstantDocumentDescriptor, didFinishReauthenticationWithJWT validJWT: String) {
        if let trackedDocument = trackedDocument(for: instantClient, documentDescriptor: documentDescriptor) {
            // This is called when the reauthentication is successfull when you have tried to reauthenticate
            // a document with a JWT using the `InstantDocumentDescriptor.reauthenticate(withJWT:)` API
            // End user doesn't need to know if they are able to connect to a session using first time authentication
            // or reauthentication like in this case.
            // However, we update the JWT of the tracked document with the one that was used to reauthenticate
            // to ensure that we have the latest valid JWT for subsequent use.
            trackedDocument.JWT = validJWT
            print("Reauthentication successful for \(trackedDocument)")
        }
    }

    func instantClient(_ instantClient: InstantClient, documentDescriptor: InstantDocumentDescriptor, didFailSyncWithError error: Error) {
        if let trackedDocument = trackedDocument(for: instantClient, documentDescriptor: documentDescriptor),
           let observer = trackedDocument.observer {
            // Called whenever syncing of changes fails. We do not want to forward this to the observer
            // if this was a result of a user cancellation.
            // For ex: When `InstantDocumentManager.disableSyncing(for:) is called where any ongoing
            // syncing requests are also cancelled.
            // Syncing can also fail due to authentication token expiration or simply a network failure.
            // If it is a network failure and you have disabled automatic syncing then you should trigger a sync
            // to send the changes to the server which failed to sync earlier.
            // You can optionally use `InstantDocumentManager.enableSync(for:)` to trigger a sync manually and also enable auto-sync.
            if (error as NSError).code != NSUserCancelledError {
                let documentInfo = InstantDocumentInfo(serverURL: trackedDocument.serverURL, url: trackedDocument.url, jwt: trackedDocument.JWT, documentId: trackedDocument.documentIdentifier, encodedDocumentId: trackedDocument.encodedDocumentId)
                print("Instant Document Failed to Sync to the PSPDFKit Server. Reason: \(error.localizedDescription)")
                observer.didFailSyncing(for: documentInfo, reason: "Please ensure that you are connected to the internet. Else please restart the session with a fresh token (JWT).")
            }
        }
    }

    func instantClient(_ instantClient: InstantClient, documentDescriptor: InstantDocumentDescriptor, didFailReauthenticationWithError error: Error) {
        if let trackedDocument = trackedDocument(for: instantClient, documentDescriptor: documentDescriptor),
           let observer = trackedDocument.observer {
            // This is method is called when a reauthentication attempt using `InstantDocumentDescriptor.reauthenticate(withJWT:)` fails.
            // Reauthentication can also fail because of network issues but otherwise the JWT used to
            // reauthenticate is no longer valid.
            // You should check for the error and also verify if the user still has access to the document.
            let documentInfo = InstantDocumentInfo(serverURL: trackedDocument.serverURL, url: trackedDocument.url, jwt: trackedDocument.JWT, documentId: trackedDocument.documentIdentifier, encodedDocumentId: trackedDocument.encodedDocumentId)
            observer.didFailReauthentication(for: documentInfo, error: error)
        }
    }

}

// MARK: - InstantDocumentManagerDocumentObserver

/// Forwards the calls from the `InstantClientDelegate` to the relevant instance observing the changes for `InstantDocumentInfo`.
/// See the `InstantClientDelegate` implementation of `InstantDocumentManager` for more details.
/// All the protocols methods will be called on a background thread.
protocol InstantDocumentManagerDocumentObserver: AnyObject {

    /// Called when the authentication of a document fails. Usually called when the user no longer
    /// has access to the document or if the JWT has expired.
    func didFailAuthentication(for documentInfo: InstantDocumentInfo)

    /// Called when a reauthentication attempt of the document for the given `InstantDocumentInfo` fails.
    func didFailReauthentication(for documentInfo: InstantDocumentInfo, error: Error)

    /// Called when the relevant `InstantClient` finishes downloading for the Document and it is ready
    /// for annotation editing.
    /// See InstantClientDelegate.instantClient(_:didFinishDownloadFor:) for more details.
    func didFinishDownload(for documentInfo: InstantDocumentInfo)

    /// Called when the downloading for an earlier requested document (`InstantDocumentInfo`) fails.
    /// See InstantClientDelegate.instantClient(_:documentDescriptor:didFailDownloadWithError:) for more details.
    func didFailDownload(for documentInfo: InstantDocumentInfo, error: Error)

    /// Called when syncing the Instant document changes fails.
    func didFailSyncing(for documentInfo: InstantDocumentInfo, reason: String)

}

// MARK: - InstantDocumentManagerError

enum InstantDocumentManagerError: Error, LocalizedError {
    case documentInUse

    var errorDescription: String? {
        switch self {
        case .documentInUse:
            return "The document requested for editing is already in use by some other instance."
        }
    }
}
