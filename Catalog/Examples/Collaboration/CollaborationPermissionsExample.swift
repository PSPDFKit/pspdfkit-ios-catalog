//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Instant
import PSPDFKit
import PSPDFKitUI

class CollaborationPermissionsExample: Example, UserPickerViewControllerDelegate {

    override init() {
        super.init()

        title = "Collaboration Permissions Example"
        contentDescription = "Limit the permissions for collaborative editing of annotations and comments for a document."
        category = .collaboration
        priority = 4
    }

    /// `UIViewController` responsible for displaying the document in a `InstantViewController` subclass.
    var targetViewController: UIViewController?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let userPickerViewController = UserPickerViewController(delegate: self)
        targetViewController = userPickerViewController
        return userPickerViewController
    }

    fileprivate func userPickerViewController(_ userPickerViewController: UserPickerViewController, didSelectUser user: User) {
        presentNewSession(for: user)
    }

    /// Connects to the Example API Client to get the document info for the current example
    /// and then displays that document in a `InstantViewController`.
    private func presentNewSession(for user: User) {
        guard let presentingController = targetViewController else {
            print("CollaborationPermissionsExample: Can not present a new Collaboration Permissions document session since the target view controller is unavailable.")
            return
        }
        let jwtParams = user.makeJWTClaims()

        // Create a `WebExamplesAPIClient` instance using the URL of the client server
        // that has the list of documents the particular user can access.
        //
        // `WebExamplesAPIClient` can make calls to the server to get the document info required
        // to connect to a Nutrient Document Engine instance.
        //
        // For the purpose of this example we are using the Nutrient Web SDK Catalog server.
        // In your app, this should be replaced by the URL of your that is interacting with your Nutrient Document Engine.
        // See https://www.nutrient.io/guides/ios/instant-synchronization/ for more details.
        let apiClient = WebExamplesAPIClient(baseURL: InstantWebExamplesServerURL, delegate: self)

        let progressHUDItem = StatusHUDItem.indeterminateProgress(withText: "Creating")
        progressHUDItem.setHUDStyle(.black)

        progressHUDItem.push(animated: true, on: presentingController.view.window) { [weak self] in
            // Asking the Nutrient Web SDK Catalog example server to create a new session
            // for the given user and the specified document identifier.
            // It should ideally provide a signed JWT (and the Nutrient Document Engine if not already available)
            // that can be used by the `InstantClient` to access and download the document for iOS.
            apiClient.createNewSession(documentIdentifier: .collaborationPermissions, jwtParameters: jwtParams) { result in
                DispatchQueue.main.async {
                    progressHUDItem.pop(animated: true, completion: nil)

                    switch result {
                    case let .success(documentInfo):
                        self?.presentInstantViewController(for: documentInfo, user: user, on: presentingController)
                    case .failure(.cancelled):
                        break // Do not show the alert if user cancelled the request themselves.
                    case let .failure(otherError):
                        presentingController.showAlert(withTitle: "Couldn’t Get Instant Document Info", message: otherError.localizedDescription)
                    }
                }
            }
        }
    }

    private func presentInstantViewController(for instantDocumentInfo: InstantDocumentInfo, user: User, on viewController: UIViewController) {
        // Set up the configuration to be used by the Collaboration Options when displaying the document.
        let configuration = InstantCollaborationOptionsViewControllerConfiguration(
            documentIdentifierForNewSession: .collaborationPermissions,
            allowJoiningExistingSessions: false,
            allowCreatingNewSessions: false,
            allowsOpeningArbitraryDocuments: false
        )
        let instantViewController = CollaborationPermissionInstantDocumentViewController(documentInfo: instantDocumentInfo, user: user)
        instantViewController.collaborationOptionsConfiguration = configuration
        let navigationController = UINavigationController(rootViewController: instantViewController)
        navigationController.modalPresentationStyle = .fullScreen
        viewController.present(navigationController, animated: true)
    }
}

/// Represents the users of the Collaboration Permissions Example.
private struct User {
    static let teacher = User(displayName: "Teacher", isTeacher: true)
    static let olivia = User(displayName: "Olivia")
    static let lucas = User(displayName: "Lucas")
    static let john = User(displayName: "John")
    static let mary = User(displayName: "Mary")

    private init(displayName: String, isTeacher: Bool = false) {
        self.displayName = displayName
        self.isTeacher = isTeacher

        if isTeacher {
            displayPermissions = [
                "You can view public annotations and comments created by all students. You cannot edit them, but you can delete them.",
                "Students can view public annotations and comments created by you, but they cannot edit or delete them.",
                "You cannot view annotations or comments created by students in private mode.",
                "Annotations or comments that you add in private mode won't be visible to students.",
            ]
        } else {
            displayPermissions = [
                "You can view the annotations created by teacher on your document.",
                "You can see comments and replies made by teacher on your document.",
                // TODO: Inspect the text.
                "You can see comments and annotations made by you.",
                "You cannot edit or delete comments and annotations created by teacher on your document.",
                "You cannot see annotations/comments added by other students."
            ]
        }
    }

    let displayName: String

    /// Whether the given user has the role of a Teacher in the context of the Collaboration Permissions example.
    let isTeacher: Bool

    /// Expansion on the permissions set using the `makeJWTClaims` API.
    let displayPermissions: [String]

    /// The annotations/comments belonging to this collaboration permission group are visible to all
    /// the users in Collaboration Permissions example.
    var publicGroup: String { isTeacher ? "teacher" : displayName.lowercased() }

    /// Collaboration Permissions Group used by the Collaboration Permissions example for creating
    /// annotations and comments that are visible privately based on the user.
    ///
    /// Annotations/comments created by a Student where the creations belong to a private group
    /// can only be viewed by students.
    ///
    ///
    /// While annotations/comments created by a user of a teacher role that belong to a private group
    /// are only visible to the teacher.
    var privateGroup: String { isTeacher ? "private_teacher" : "private_students" }

    /// The required parameters for setting up Collaboration Permissions for the user that are set in the
    /// JWT created to access the document using Instant.
    ///
    /// Includes:
    ///  - user id
    ///  - default group
    ///  - collaboration permissions.
    ///
    /// These parameters are sent over to the Web Examples Server which creates the JWT that is used
    /// by to access documents by the Collaboration Permissions Catalog example.
    func makeJWTClaims() -> [String: Any] {
        let userID = "user_\(displayName.lowercased())"
        var permissions = [
            "annotations:view:self",
            "annotations:view:group=\(privateGroup)",
            "annotations:view:group=olivia",
            "annotations:view:group=lucas",
            "annotations:view:group=john",
            "annotations:view:group=mary",
            "annotations:view:group=teacher",
            "annotations:view:group=signature",
            "annotations:edit:self",
            "annotations:delete:self",
            "annotations:set-group:group=\(publicGroup)",
            "annotations:set-group:group=\(privateGroup)",
            "comments:view:group=\(privateGroup)",
            "comments:view:group=olivia",
            "comments:view:group=lucas",
            "comments:view:group=john",
            "comments:view:group=mary",
            "comments:view:group=teacher",
            "comments:view:self",
            "comments:edit:self",
            "comments:delete:self",
            "comments:set-group:group=\(publicGroup)",
            "comments:set-group:group=\(privateGroup)",
            "annotations:set-group:group=signature",
            "comments:reply:all",
        ]
        if isTeacher {
            permissions.append(contentsOf: [
                "annotations:delete:group=olivia",
                "annotations:delete:group=lucas",
                "annotations:delete:group=john",
                "annotations:delete:group=mary",
                "comments:delete:group=olivia",
                "comments:delete:group=lucas",
                "comments:delete:group=john",
                "comments:delete:group=mary",
            ])
        }

        return [
            "user_id": userID,
            "default_group": publicGroup,
            "collaboration_permissions": permissions
        ]
    }
}

/// Displays an Instant document that allows the user to switch between the
/// public and private annotation/comment creation mode.
private class CollaborationPermissionInstantDocumentViewController: InstantDocumentViewController {

    /// User Role for whom the current document is being displayed.
    let user: User

    /// Image used in the context menu to depict the public mode annotation creation.
    let publicModeImage = UIImage(namedInCatalog: "show")!

    /// Image used in the context menu to depict the private mode annotation creation.
    let privateModeImage = UIImage(namedInCatalog: "private-mode")!

    /// Button that allows you to change between the public and private annotation/comments creation mode.
    lazy var groupModeButton: UIBarButtonItem = {
        let menu = UIMenu(children: self.changeGroupActions())
        return UIBarButtonItem(title: nil, image: publicModeImage, menu: menu)
    }()

    init(documentInfo: InstantDocumentInfo, user: User, lastViewedDocumentInfoKey: String? = nil) {
        self.user = user
        super.init(documentInfo: documentInfo, lastViewedDocumentInfoKey: lastViewedDocumentInfoKey)
        navigationItem.setRightBarButtonItems([collaborateButtonItem, annotationButtonItem, groupModeButton], for: .document, animated: false)

        if self.user.isTeacher {
            title = user.displayName
        } else {
            title = "\(user.displayName) (Student)"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Use the user's display name as the annotation's creator name.
        document?.defaultAnnotationUsername = user.displayName
    }

    /// Changes the annotation/comment creation mode to public/private based on the parameter passed.
    /// Internally it changes the default group for the newly created annotations and comments
    /// for the displayed document.
    ///
    /// Displays an alert
    /// See `InstantDocumentDescriptor.overrideDefaultGroup(with:)` for more details.
    func changeVisibilityMode(isPublic: Bool) -> Bool {
        var changedGroup: String
        if isPublic {
            changedGroup = user.publicGroup
        } else {
            changedGroup = user.privateGroup
        }

        var didSucceed = false
        do {
            try InstantDocumentManager.shared.changeDefaultGroup(changedGroup, for: documentInfo)
            didSucceed = true
        } catch let error {
            showAlert(withTitle: "Failed to change the default group for Collaboration Permissions", message: error.localizedDescription)
        }
        return didSucceed
    }

    func changeGroupActions() -> [UIAction] {
        let publicMode = UIAction.Identifier("Public Mode")
        let privateMode = UIAction.Identifier("Private Mode")
        return [
            UIAction(title: publicMode.rawValue, image: publicModeImage, identifier: publicMode) { [weak self] _ in
                if let strongSelf = self,
                   strongSelf.changeVisibilityMode(isPublic: true) == true {
                    strongSelf.groupModeButton.image = strongSelf.publicModeImage
                }
            },
            UIAction(title: privateMode.rawValue, image: privateModeImage, identifier: privateMode) { [weak self] _ in
                if let strongSelf = self,
                   strongSelf.changeVisibilityMode(isPublic: false) == true {
                    strongSelf.groupModeButton.image = strongSelf.privateModeImage
                }
            }
        ]
    }
}

// MARK: - Helpers

extension CollaborationPermissionsExample: WebExamplesAPIClientDelegate {

    func examplesAPIClient(_ apiClient: WebExamplesAPIClient, didReceiveBasicAuthenticationChallenge challenge: URLAuthenticationChallenge, completion: @escaping (URLCredential?) -> Void) {
        targetViewController?.presentBasicAuthPrompt(for: challenge) { username, password in
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

private protocol UserPickerViewControllerDelegate: AnyObject {

    /// Called whenever the user is selected from the User listing.
    func userPickerViewController(_ userPickerViewController: UserPickerViewController, didSelectUser user: User)
}

/// This controller displays the list of User Roles that a user can join as for the Collaboration Permissions example.
/// Upon selection of the role, a new document session is created with a set
/// of Collaboration Permissions for that user.
/// Permissions for the Roles are defined in the `User` type.
/// To learn more about how to set the permissions, please see: https://www.nutrient.io/guides/web/collaboration-permissions/defining-permissions/
private class UserPickerViewController: UITableViewController {

    enum SectionIdentifier: Int {
        case header
        case student
        case teacher
    }

    struct Section {
        let identifier: SectionIdentifier
        let header: String?
        let rows: [User]
        let footer: String?
    }

    weak var delegate: UserPickerViewControllerDelegate?

    /// List of user roles.
    private let sections = [
        Section(identifier: .header,
                header: "Collaborate on the document as one of the roles below.\nPlease select one to continue.",
                rows: [], footer: nil),
        Section(identifier: .student,
                header: "STUDENT ROLES",
                rows: [.olivia, .lucas, .john, .mary],
                footer: "Student's Permissions"),
        Section(identifier: .teacher,
                header: "TEACHER ROLE",
                rows: [.teacher],
                footer: "Teacher's Permissions")
    ]

    private let textCellReuseIdentifier = "Regular Text Cell"

    init(delegate: UserPickerViewControllerDelegate) {
        self.delegate = delegate
        super.init(style: .insetGrouped)
        title = "Collaboration Permissions"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

#if !os(visionOS)
        tableView.keyboardDismissMode = .onDrag
#endif
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: textCellReuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: textCellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = user.isTeacher ? "Evaluate Paper" : user.displayName
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let tableSection = sections[section]
        guard let footerText = tableSection.footer else { return nil }

        let footer = UIView()
        let rolePermissions = UIButton(type: .system)
        rolePermissions.setTitleColor(.systemBlue, for: .normal)
        rolePermissions.setTitle(footerText, for: .normal)
        rolePermissions.contentHorizontalAlignment = .left
        footer.addSubview(rolePermissions)

        var targetSelector: Selector
        if tableSection.identifier == .teacher {
            targetSelector = #selector(showTeacherRolePermissions)
        } else {
            targetSelector = #selector(showStudentRolePermissions)
        }
        rolePermissions.addTarget(self, action: targetSelector, for: .touchDown)

        rolePermissions.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = footer.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            rolePermissions.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            rolePermissions.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            rolePermissions.topAnchor.constraint(equalTo: safeArea.topAnchor),
            rolePermissions.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
        ])

        return footer
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = sections[indexPath.section].rows[indexPath.row]
        delegate?.userPickerViewController(self, didSelectUser: user)
    }

    @objc private func showStudentRolePermissions(_ sender: UIButton) {
        // All students have the same permissions so we go with an arbitrary student.
        showPermissions(for: .olivia, sender: sender)
    }

    @objc private func showTeacherRolePermissions(_ sender: UIButton) {
        showPermissions(for: .teacher, sender: sender)
    }

    /// Presents a controller with a list of permissions granted to the given user role.
    private func showPermissions(for user: User, sender: UIButton) {
        let rolesListingController = PermissionsListViewController(user: user)
        let navController = UINavigationController(rootViewController: rolesListingController)
        navController.popoverPresentationController?.sourceView = sender
        present(navController, animated: true)
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }
}

/// Presents a list of actions permissable for the User Role.
/// These permissions are defined in the JWT used to access an Instant document.
/// https://www.nutrient.io/guides/web/collaboration-permissions/defining-permissions/
private class PermissionsListViewController: UIViewController {

    let user: User

    private lazy var closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissModalController))

    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        view.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        let spacingConstant = 16.0
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: spacingConstant),
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacingConstant),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacingConstant),
        ])

        title = user.isTeacher ? "Teacher's Permissions" : "Student's Permissions"
        label.text = user
            .displayPermissions
            .map { "• \($0)" }
            .joined(separator: "\n")
        navigationItem.leftBarButtonItems = [closeButton]
    }

    @objc func dismissModalController() {
        dismiss(animated: true, completion: nil)
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }
}
