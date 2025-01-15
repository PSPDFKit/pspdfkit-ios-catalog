//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Instant
import PSPDFKit
import PSPDFKitUI

/// Configuration options for `InstantCollaborationOptionsViewController`.
struct InstantCollaborationOptionsViewControllerConfiguration {

    /// The document identifier to be used for the creation of a new Instant collaboration session.
    /// Defaults to `InstantDemoDocumentIdentifier`.
    let documentIdentifierForNewSession: InstantExampleDocumentIdentifier

    /// Whether the Collaboration option of joining an existing session that allows entering a
    /// document sharing URL is allowed or not.
    /// Defaults to `true`.
    let allowJoiningExistingSessions: Bool

    /// Whether the Collaboration option of starting a new session for that document should
    /// be provided or not.
    /// Defaults to `true`.
    let allowCreatingNewSessions: Bool

    /// Allows the example to open arbitrary documents other than the specific document for which
    /// the example is designed to work with.
    /// Defaults to `true`.
    let allowsOpeningArbitraryDocuments: Bool

    /// The default configuration — allows creating sessions and joining existing ones, using the demo document.
    static func `default`() -> Self {
        .init(documentIdentifierForNewSession: .demoDocument, allowJoiningExistingSessions: true, allowCreatingNewSessions: true, allowsOpeningArbitraryDocuments: true)
    }

    /// Whether the Collaboration option allows creating opening a new session with the given
    /// document identifier.
    /// Returns `true` if `allowsOpeningArbitraryDocuments` is enabled.
    func canOpenDocument(with identifier: InstantExampleDocumentIdentifier) -> Bool {
        if allowsOpeningArbitraryDocuments {
            return true
        } else {
            return identifier == documentIdentifierForNewSession
        }
    }
}

protocol InstantCollaborationOptionsViewControllerDelegate: AnyObject {

    /// Called when the `InstantDocumentInfo` for the document identifier provided by
    /// `documentIdentifierForNewSession` is received from your server backed.
    func instantCollaborationController(_ instantCollaborationController: InstantCollaborationOptionsViewController, didCreateNewSession documentInfo: InstantDocumentInfo)
}

/// Lists the collaboration options for the given `InstantDocumentInfo`.
class InstantCollaborationOptionsViewController: UITableViewController {

    var documentInfo: InstantDocumentInfo

    lazy var apiClient = WebExamplesAPIClient(delegate: self)

    /// Source item whose action was responsible for displaying of the current `InstantCollaborationOptionsViewController` instance.
    weak var sender: AnyObject?

    /// A reference to the text field in the cell so it can be disabled when starting a new group to avoid duplicate network requests.
    weak var urlTextField: UITextField?

    weak var delegate: InstantCollaborationOptionsViewControllerDelegate?

    let configuration: InstantCollaborationOptionsViewControllerConfiguration

    init(documentInfo: InstantDocumentInfo, configuration: InstantCollaborationOptionsViewControllerConfiguration = .default(), sender: AnyObject?) {
        self.documentInfo = documentInfo
        self.configuration = configuration
        self.sender = sender

        super.init(style: .grouped)

        title = "Collaboration Options"
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.openInSafari.rawValue)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.shareDocumentLink.rawValue)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.newGroup.rawValue)
        tableView.register(InstantExampleDocumentLinkCell.self, forCellReuseIdentifier: CellIdentifier.urlField.rawValue)
    #if !os(visionOS)
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.scanCode.rawValue)
    #endif
    }

    private enum CellIdentifier: String {
        case openInSafari
        case shareDocumentLink
        case newGroup
        #if !os(visionOS)
        case scanCode
        #endif
        case urlField
    }

    private struct Row {
        let identifier: CellIdentifier
        let allowsHighlight: Bool
    }

    private struct Section {
        let header: String?
        let rows: [Row]
        let footer: String?
    }

    /// Data to show in the table view.
    private lazy var sections: [Section] = {
        var allowedSections = [Section]()

        // Create the first section that allows extending and sharing the ongoing session.
        let extendSessionSection = Section(header: "Extend This Session", rows: [Row(identifier: .openInSafari, allowsHighlight: true), Row(identifier: .shareDocumentLink, allowsHighlight: true)], footer: "Share the current document's link to collaborate with other Instant users.")
        allowedSections.append(extendSessionSection)

        if configuration.allowCreatingNewSessions {
            // Create the section that allows starting a new collaboration session.
            let newSessionSection = Section(header: "Start a new session", rows: [Row(identifier: .newGroup, allowsHighlight: true)], footer: "Get a new document link, then collaborate by entering it in Nutrient Catalog on another device, or opening the document's link in a web browser.")
            allowedSections.append(newSessionSection)
        }

        if configuration.allowJoiningExistingSessions {
            // Create the section that allows joining an existing session.
            var joinSessionRows = [Row]()

            // Add the cell that allows scanning the QR code of the example.
            // We add this cell only on actual devices.
            #if !targetEnvironment(simulator) && !os(visionOS)
                let scanQRCodeRow = Row(identifier: .scanCode, allowsHighlight: true)
                joinSessionRows.append(scanQRCodeRow)
            #endif

            let urlFieldRow = Row(identifier: .urlField, allowsHighlight: false)
            joinSessionRows.append(urlFieldRow)

            let joinSessionSection = Section(header: "Join an existing session", rows: joinSessionRows, footer: "Enter a document link's from PDF Viewer or Nutrient Catalog on another device, or from a web browser showing web-examples.our.services.nutrient-powered.io.")
            allowedSections.append(joinSessionSection)
        }

        return allowedSections
    }()

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: row.identifier.rawValue, for: indexPath)
        cell.textLabel?.textColor = tableView.tintColor

        switch row.identifier {
        case .shareDocumentLink:
            cell.textLabel?.text = "Share Document Link"
        case .openInSafari:
            cell.textLabel?.text = "Open in Safari"

        case .newGroup:
            cell.textLabel?.text = "Start Session"

        #if !os(visionOS)
        case .scanCode:
            cell.textLabel?.text = "Scan QR Code"
        #endif

        case .urlField:
            let textField = (cell as! InstantExampleDocumentLinkCell).textField
            urlTextField = textField
            textField.delegate = self
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].rows[indexPath.row].allowsHighlight
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowId = sections[indexPath.section].rows[indexPath.row].identifier

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        switch rowId {
        case .openInSafari:
            UIApplication.shared.open(documentInfo.url)
        case .shareDocumentLink:
            tableView.deselectRow(at: indexPath, animated: true)
            let activityViewController = UIActivityViewController(activityItems: [documentInfo.url], applicationActivities: nil)
            if let presentingViewController {
                #if os(visionOS)
                activityViewController.popoverPresentationController?.sourceItem = sender as? UIView
                #else
                activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
                #endif
                presentingViewController.dismiss(animated: true) {
                    presentingViewController.present(activityViewController, animated: true)
                }
            } else {
                print("Instant Warning: Unable to find a view controller to present the UIActivityViewController for sharing the document link.")
            }
        case .newGroup:
            createNewSession(documentIdentifier: configuration.documentIdentifierForNewSession)
#if !os(visionOS)
        case .scanCode:
            requestPermissionAndPresentScanner()
#endif
        case .urlField:
            fatalError("Shouldn’t be able to select URL field cell.")
        }
    }

    /// Creates a new Instant Collaboration session for the given document identifier and sends the new session info to the delegate if successful.
    private func createNewSession(documentIdentifier: InstantExampleDocumentIdentifier) {
        showProgressHUD(with: "Creating") { progressHUDItem in
            self.apiClient.createNewSession(documentIdentifier: documentIdentifier) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)
                    self.didReceiveNewSession(result)
                }
            }
        }
    }

    /// Joins an existing Instant Collaboration session using the session URL and sends the new session info to the delegate if successful.
    private func joinExistingSession(_ sessionURL: URL) {
        let documentIdentifier = documentIdentifierFromURL(sessionURL)
        // These examples are designed to work with specific documents.
        guard configuration.canOpenDocument(with: documentIdentifier) else {
            showAlert(withTitle: "Incompatible Document", message: "The example document session you are trying to join is it not compatible with the currently open example.")
            return
        }

        showProgressHUD(with: "Joining") { progressHUDItem in
            self.apiClient.resolveExistingSessionURL(sessionURL) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)
                    self.didReceiveNewSession(result)
                }
            }
        }
    }

    /// Extracts the document identifier of the Example from the URL.
    private func documentIdentifierFromURL(_ url: URL) -> InstantExampleDocumentIdentifier {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let exampleItem = components.queryItems?.first(where: { $0.name == "example" }),
           let exampleName = exampleItem.value {
            return .init(rawValue: exampleName)
        } else {
            return .init(rawValue: url.lastPathComponent)
        }
    }

    /// Manages the result of a new session creation or joining of an existing session by informing
    /// the `delegate` if a new session was created successfully otherwise presents the error
    /// as an alert.
    private func didReceiveNewSession(_ result: Result<InstantDocumentInfo, WebExamplesAPIClientError>) {
        switch result {
        case let .success(newDocumentInfo):
            delegate?.instantCollaborationController(self, didCreateNewSession: newDocumentInfo)
        case .failure(WebExamplesAPIClientError.cancelled):
            break // Do not show the alert if user cancelled the request themselves.
        case let .failure(otherError):
            showAlert(withTitle: "Couldn’t Get Instant Document Info", message: otherError.localizedDescription)
        }
    }

    /// Shows a progress HUD with the given text and performs the `operation` closure on presenting
    /// the progress HUD.
    /// The `operation` closure is responsible for dismissing the presented progress HUD.
    private func showProgressHUD(with hudText: String, operation: @escaping (StatusHUDItem) -> Void) {
        let progressHUDItem = StatusHUDItem.indeterminateProgress(withText: hudText)
        progressHUDItem.setHUDStyle(.black)

        progressHUDItem.push(animated: true, on: view.window) {
            operation(progressHUDItem)
        }
    }

    #if !os(visionOS)
    private func requestPermissionAndPresentScanner() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted: Bool) -> Void in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                if granted {
                    let scannerVC = ScannerViewController()
                    scannerVC.delegate = self
                    let navigationVC = UINavigationController(rootViewController: scannerVC)
                    navigationVC.modalPresentationStyle = .fullScreen

                    self.navigationController?.present(navigationVC, animated: true, completion: nil)
                } else {
                    self.tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
                    self.showAlert(withTitle: "Camera Access Needed", message: "To scan QR codes, enable camera access in the Settings app.")
                }
            }
        }
    }
    #endif
}

// MARK: - Text field delegate

extension InstantCollaborationOptionsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, !text.isEmpty else {
            textField.resignFirstResponder()
            return true
        }

        if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            joinExistingSession(url)
        } else {
            showAlert(withTitle: "Couldn’t Join Group", message: "This is not a link. Please enter an Instant document link.")
        }

        return true
    }
}

// MARK: - Scanner view controller delegate
#if !os(visionOS)
extension InstantCollaborationOptionsViewController: ScannerViewControllerDelegate {

    func scannerViewController(_ scannerViewController: ScannerViewController, didFinishScanningWith result: BarcodeScanResult) {
        if case .success(let barcode) = result {
            urlTextField?.text = barcode
        }

        self.dismiss(animated: true) {
            switch result {
            case .success(let barcode):
                if let url = URL(string: barcode) {
                    self.joinExistingSession(url)
                } else {
                    self.showAlert(withTitle: "Couldn’t Join Group", message: "This is not a link. Please scan the QR code from one of the examples at https://web-examples.our.services.nutrient-powered.io/")
                }
            case .failure(let errorMessage):
                self.showAlert(withTitle: "Couldn’t Scan QR Code", message: errorMessage)
            }
        }
    }
}
#endif

extension InstantCollaborationOptionsViewController: WebExamplesAPIClientDelegate {

    func examplesAPIClient(_ apiClient: WebExamplesAPIClient, didReceiveBasicAuthenticationChallenge challenge: URLAuthenticationChallenge, completion: @escaping (URLCredential?) -> Void) {
        presentBasicAuthPrompt(for: challenge) { username, password in
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
