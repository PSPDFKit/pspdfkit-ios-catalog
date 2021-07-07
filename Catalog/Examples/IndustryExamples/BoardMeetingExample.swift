//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
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

/// This example uses the following PSPDFKit features:
/// - Viewer
/// - Annotations
/// - Instant
///
/// See https://pspdfkit.com/pdf-sdk/ios/ for the complete list of features for PSPDFKit for iOS.

class BoardMeetingExample: IndustryExample {
    override init() {
        super.init()

        title = "Board Meeting"
        contentDescription = "Shows how to create or join a collaborative editing session for a board meeting."
        category = .industryExamples
        priority = 2
        extendedDescription = "This example shows how multiple attendees can annotate and collaborate on the same document in real time, which can be useful for reviewing a report during a virtual meeting."
        url = URL(string: "https://pspdfkit.com/blog/2021/industry-solution-board-meeting-ios/")!
        if #available(iOS 14.0, *) {
            image = UIImage(systemName: "person.2")
        }

        if #available(macCatalyst 14, *) {} else {
            targetDevice = []
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        return BoardMeetingExampleViewController(with: self)
    }
}

/// Shows UI to either start a new collaboration session or join an existing session.
private class BoardMeetingExampleViewController: UITableViewController {

    private var moreInfo: MoreInfoCoordinator?

    private lazy var apiClient = WebExamplesAPIClient(delegate: self)

    /// A reference to the text field in the cell so it can be disabled when starting a new group to avoid duplicate network requests.
    weak var codeTextField: UITextField?

    init(with example: IndustryExample) {
        super.init(style: .grouped)
        title = "Board Meeting"

        // Add the more info button.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        navigationItem.leftBarButtonItem = moreInfo?.barButton
        navigationItem.leftItemsSupplementBackButton = true
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.keyboardDismissMode = .onDrag
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.newGroup.rawValue)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier.scanCode.rawValue)
        tableView.register(InstantExampleDocumentLinkCell.self, forCellReuseIdentifier: CellIdentifier.urlField.rawValue)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        moreInfo?.showAlertIfNeeded()
    }

    enum CellIdentifier: String {
        case newGroup
        case scanCode
        case urlField
    }

    struct Row {
        let identifier: CellIdentifier
        let allowsHighlight: Bool
    }

    struct Section {
        let header: String?
        let rows: [Row]
        let footer: String?
    }

    /// Data to show in the table view.
    private let sections: [Section] = [
        Section(header: "Start a new meeting", rows: [Row(identifier: .newGroup, allowsHighlight: true)], footer: "Get a new document link, then collaborate by entering it in PSPDFKit Catalog on another device, or opening the document link in a web browser."),
        Section(header: "Join a meeting", rows: [Row(identifier: .scanCode, allowsHighlight: true), Row(identifier: .urlField, allowsHighlight: false)], footer: "Scan or enter a document link from PDF Viewer or PSPDFKit Catalog on another device, or from a web browser showing pspdfkit.com/instant/demo or web-examples.pspdfkit.com."),
    ]

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
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)

        switch row.identifier {
        case .newGroup:
            cell.textLabel?.text = "Start a meeting"
            return cell

        case .scanCode:
            cell.textLabel?.text = "Scan QR Code"
            return cell

        case .urlField:
            let textField = (cell as! InstantExampleDocumentLinkCell).textField

            codeTextField = textField

            textField.delegate = self
            return cell
        }
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

        switch rowId {
        case .newGroup:
            createNewSession(for: InstantBoardMeetingDocumentIdentifier)
        case .scanCode:
            if #available(macCatalyst 14, *) {
                requestPermissionAndPresentScanner()
            } else {
                print("This example requires iOS 13 or Catalyst on Big Sur or higher.")
            }
        case .urlField:
            fatalError("Shouldn’t be able to select URL field cell.")
        }
    }

    /// Creates a new Instant Collaboration session for the given document identifier and sends the new session info to the delegate if successful.
    private func createNewSession(for documentIdentifier: String) {
        showProgressHUD(with: "Creating") { progressHUDItem in
            self.apiClient.createNewSession(for: documentIdentifier) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)
                    self.didReceiveNewSession(result)
                }
            }
        }
    }

    /// Joins an existing Instant Collaboration session using the session URL and sends the new session info to the delegate if successful.
    private func joinExistingSession(_ sessionURL: URL) {
        showProgressHUD(with: "Joining") { progressHUDItem in
            self.apiClient.resolveExistingSessionURL(sessionURL) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)
                    self.didReceiveNewSession(result)
                }
            }
        }
    }

    /// Manages the result of a new session creation or joining of an existing session by informing
    /// the `delegate` if a new session was created successfully otherwise presents the error
    /// as an alert.
    private func didReceiveNewSession(_ result: Result<InstantDocumentInfo, WebExamplesAPIClientError>) {
        switch result {
        case let .success(documentInfo):
            presentInstantViewController(for: documentInfo)
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

    private func presentInstantViewController(for documentInfo: InstantDocumentInfo) {
        let instantViewController = InstantDocumentViewController(documentInfo: documentInfo)
        let navigationController = UINavigationController(rootViewController: instantViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    @available(macCatalyst 14, *)
    private func requestPermissionAndPresentScanner() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted: Bool) -> Void in
            DispatchQueue.main.async {
                guard let self = self else {
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

}

// MARK: - Text field delegate

extension BoardMeetingExampleViewController: UITextFieldDelegate {

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

@available(macCatalyst 14, *)
extension BoardMeetingExampleViewController: ScannerViewControllerDelegate {

    func scannerViewController(_ scannerViewController: ScannerViewController, didFinishScanningWith result: BarcodeScanResult) {
        if case .success(let barcode) = result {
            codeTextField?.text = barcode
        }

        self.dismiss(animated: true) {
            switch result {
            case .success(let barcode):
                if let url = URL(string: barcode) {
                    self.joinExistingSession(url)
                } else {
                    self.showAlert(withTitle: "Couldn’t Join Group", message: "This is not a link. Please enter an Instant document link.")
                }
            case .failure(let errorMessage):
                self.showAlert(withTitle: "Couldn’t Scan QR Code", message: errorMessage)
            }
        }
    }
}

extension BoardMeetingExampleViewController: WebExamplesAPIClientDelegate {

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
