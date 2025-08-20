//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// A container view controller meant for adding a controller to be presented as a sidebar
/// in a UISplitViewController so that it can be detached and also be presented modally.
class SidebarControllersContainingViewController: UIViewController {

    /// The controller added as a child view controller that can be detached and presented modally.
    var childViewController: UIViewController

    /// Whether `childViewController` is added as a child controller.
    var isChildControllerContained: Bool {
        return childViewController.parent == self
    }

    /// Navigation controller responsible for presenting `childViewController` modally.
    var modalNavigationController: UINavigationController?

    /// Button added to dismiss the `childViewController` when presented modally.
    private lazy var closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissModalController))

    /// Initializes a new containing controller adding the given controller as a child controller.
    ///
    /// We want to show the same Document Info views from the sidebar in a modal in compact horizontal size class layout.
    /// `UISplitViewController` doesn't allow us changing its direct children even in its delegate callbacks.
    /// This is why we add the Document Info views to be shown in the sidebar of the `UISplitViewController` as a
    /// child controller of this controller and add this controller as the primary controller of the `UISplitViewController`.
    /// When the horizontal size class changes to compact and the sidebar button is toggled, this controller
    /// can be asked to detach the Document Info views and present them manually.
    ///
    /// - Parameter childViewController: The controller to be added as a child view controller.
    init(childViewController: UIViewController) {
        self.childViewController = childViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addContainedViewControllerIfNecessary()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNavigationAndToolbars()
    }

    // MARK: Modal Sidebar Presentation

    /// Adds `childViewController` backs as a contained view controller if it is not already.
    func addContainedViewControllerIfNecessary() {
        if isChildControllerContained { return }

        modalNavigationController?.viewControllers = []
        modalNavigationController = nil

        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)

        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childViewController.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor), // Use the safeAreaLayoutGuide on this one because otherwise the cell separators are not inset.
            childViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        updateNavigationAndToolbars()
    }

    /// Removes the `isChildControllerContained` as its child view controller.
    func removeContainedViewControllerIfNecessary() {
        if isChildControllerContained == false { return }

        childViewController.view.removeFromSuperview()
        childViewController.removeFromParent()
        updateNavigationAndToolbars()
    }

    /// Updates the navigation and toolbars based on the containment status of the `childViewController`.
    /// `childViewController` bar items are added to self if it is contained.
    /// Otherwise the current items are removed.
    func updateNavigationAndToolbars() {
        if isChildControllerContained {
            let childControllerNavigationItem = childViewController.navigationItem

            // We add a close button to `childViewController` when it is displayed in a modal
            // so we need to filter it out when it is add back to the sidebar.
            childControllerNavigationItem.leftBarButtonItems = childControllerNavigationItem.leftBarButtonItems?.filter {
                $0 != closeButton
            }

            navigationItem.title = childControllerNavigationItem.title
            navigationItem.titleView = childControllerNavigationItem.titleView
            navigationItem.leftBarButtonItems = childControllerNavigationItem.leftBarButtonItems
            navigationItem.rightBarButtonItems = childControllerNavigationItem.rightBarButtonItems
            navigationItem.searchController = childControllerNavigationItem.searchController

            if let toolbarItems = childViewController.toolbarItems {
                setToolbarItems(toolbarItems, animated: false)
            }
        } else {
            navigationItem.titleView = nil
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = nil
            navigationItem.searchController = nil
            setToolbarItems(nil, animated: false)
        }
    }

    /// Presents the `childViewController` modally inside a `PDFNavigationController` on top of the
    /// given `presenter` controller.
    ///
    /// The `childViewController` is detached from the container (`self`). It is the responsibility
    /// of the caller of this method to add `childViewController` back as a child controller by calling
    /// `addContainedViewControllerIfNecessary`.
    ///
    /// - Parameter presenter: The controller to use to present `childViewController`.
    func presentContainedViewControllerModally(on presenter: UIViewController) {
        removeContainedViewControllerIfNecessary()

        var navigationController: UINavigationController
        if let childNavigationController = childViewController.navigationController, childNavigationController == modalNavigationController {
            navigationController = childNavigationController

            // Do nothing if the contained controller is already presented on the presenter.
            // Otherwise dismiss it and present it on the presenter.
            if presenter.presentedViewController != navigationController {
                navigationController.dismiss(animated: true) {
                    presenter.present(navigationController, animated: true, completion: nil)
                }
            }
        } else {
            navigationController = PDFNavigationController(rootViewController: childViewController)
            modalNavigationController = navigationController

            // Add close button for accessibility.
            childViewController.navigationItem.leftBarButtonItem = closeButton

            presenter.present(navigationController, animated: true, completion: nil)
        }
    }

    /// Dismisses the `childViewController` presented in a modal.
    @objc func dismissModalController() {
        modalNavigationController?.dismiss(animated: true, completion: nil)
    }
}
