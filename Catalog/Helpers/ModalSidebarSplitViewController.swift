//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import UIKit

/// Generic presentation controller that manages sidebar and modal presentation of two view controllers.
///
/// This controller handles:
/// - Split view controller for sidebar presentation on iPad
/// - Modal presentation on iPhone
/// - Automatic switching between presentation modes
/// - Navigation controller hierarchy management
class ModalSidebarSplitViewController<Primary: UIViewController, Secondary: UIViewController>: UIViewController, UISplitViewControllerDelegate {

    /// Primary view controller (shown in sidebar or modal)
    let primaryViewController: Primary

    /// Secondary view controller (main content)
    let secondaryViewController: Secondary

    /// Split view controller for sidebar presentation
    private let internalSplitViewController: UISplitViewController

    /// Navigation controller for sidebar
    private var sidebarNavigationController: UINavigationController

    // MARK: - Initialization

    init(primaryViewController: Primary, secondaryViewController: Secondary) {
        self.primaryViewController = primaryViewController
        self.secondaryViewController = secondaryViewController

        // Create split view controller
        self.internalSplitViewController = UISplitViewController(style: .doubleColumn)

        // Create navigation controller for sidebar
        let navController = UINavigationController(rootViewController: primaryViewController)
        sidebarNavigationController = navController

        super.init(nibName: nil, bundle: nil)

        setupSplitViewController()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addSplitViewControllerToHierarchy()
        configureNavigationBarAppearance(for: sidebarNavigationController)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Dismiss any presented modal during size transitions to avoid navigation conflicts
        if let presentedModal = presentedViewController {
            presentedModal.dismiss(animated: false)
        }

        coordinator.animate(alongsideTransition: nil) { _ in
            // Size transition completed
            // The user can manually toggle the primary controller back if they want it
        }
    }

    // MARK: - Setup

    private func setupSplitViewController() {
        // Configure split view controller
        internalSplitViewController.primaryEdge = .leading
        internalSplitViewController.preferredDisplayMode = .oneBesideSecondary
        internalSplitViewController.delegate = self

#if !os(visionOS)
        internalSplitViewController.displayModeButtonVisibility = .never
        internalSplitViewController.presentsWithGesture = false
#endif

        // Add primary to split view as primary (sidebar) controller
        internalSplitViewController.setViewController(sidebarNavigationController, for: .primary)

        // Set secondary (main) view controller with navigation controller
        let secondaryNavController = UINavigationController(rootViewController: secondaryViewController)
        configureNavigationBarAppearance(for: secondaryNavController)
        internalSplitViewController.setViewController(secondaryNavController, for: .secondary)
    }

    /// Adds the split view controller to the view hierarchy.
    ///
    /// This method properly sets up the parent-child relationship
    /// and configures auto-resizing for the split view.
    private func addSplitViewControllerToHierarchy() {
        addChild(internalSplitViewController)
        view.addSubview(internalSplitViewController.view)
        internalSplitViewController.view.frame = view.bounds
        internalSplitViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        internalSplitViewController.didMove(toParent: self)
    }

    // MARK: - Public Interface

    /// Toggles the visibility of the primary view controller
    @objc func togglePrimaryViewController() {
        if internalSplitViewController.isCollapsed {
            // Present modally when collapsed (iPhone)
            presentPrimaryModally()
        } else {
            // Toggle sidebar visibility when not collapsed (iPad)
            if internalSplitViewController.displayMode == .secondaryOnly {
                // Sidebar is hidden, show it
                // Ensure primary is properly set up in the sidebar navigation controller
                restorePrimaryToSidebar()
                internalSplitViewController.show(.primary)
            } else {
                // Sidebar is visible, hide it
                internalSplitViewController.hide(.primary)
            }
        }
    }

    /// Dismisses primary view controller if presented modally
    func dismissPrimaryIfModal(completion: @escaping () -> Void) {
        if let presentedModal = presentedViewController {
            presentedModal.dismiss(animated: true, completion: completion)
        } else {
            completion()
        }
    }

    // MARK: - Modal Presentation

    /// Presents the primary view controller modally with a fresh navigation controller
    private func presentPrimaryModally() {
        // Safely remove from any existing parent first
        primaryViewController.removeFromParent()

        // Create a completely fresh navigation controller for modal presentation
        let modalNavController = UINavigationController(rootViewController: primaryViewController)
        configureNavigationBarAppearance(for: modalNavController)

        modalNavController.modalPresentationStyle = .pageSheet
#if !os(visionOS)
        if let sheet = modalNavController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
#endif

        // Add close button for modal presentation
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissModalPrimary))
        primaryViewController.navigationItem.rightBarButtonItem = closeButton

        present(modalNavController, animated: true)
    }

    @objc private func dismissModalPrimary() {
        guard let presentedModal = presentedViewController else { return }

        // Dismiss the specific modal navigation controller
        presentedModal.dismiss(animated: true) {
            // Modal dismissed - user can use the toggle button to show primary again
        }
    }

    /// Safely restores the primary view controller to the sidebar navigation controller
    /// This method handles the proper removal and re-addition to avoid navigation conflicts
    private func restorePrimaryToSidebar() {
        // Only restore if not already in the correct place
        if primaryViewController.parent != sidebarNavigationController {
            // Safely remove from any existing parent
            primaryViewController.removeFromParent()

            // Clear any modal-specific navigation items
            primaryViewController.navigationItem.rightBarButtonItem = nil

            // Simply set the primaryViewController as sidebar navigation controller's root.
            sidebarNavigationController.setViewControllers([primaryViewController], animated: false)
        }
    }

    // MARK: - Navigation Bar Configuration

    private func configureNavigationBarAppearance(for navigationController: UINavigationController) {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground

        navigationController.navigationBar.standardAppearance = navBarAppearance
        navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController.navigationBar.compactAppearance = navBarAppearance
        navigationController.navigationBar.compactScrollEdgeAppearance = navBarAppearance
    }

 // MARK: - UISplitViewControllerDelegate

     func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
         // When the split view controller is about to show the primary column (sidebar),
         // ensure the primary view controller is properly restored to the sidebar
         let willShowSidebar: Bool
#if os(visionOS)
         willShowSidebar = displayMode == .oneBesideSecondary
#else
         willShowSidebar = displayMode == .oneBesideSecondary || displayMode == .oneOverSecondary
#endif
         if willShowSidebar {
             // Check if we have a modal presentation that needs to be moved to sidebar
             if presentedViewController != nil {
                 // Dismiss modal and restore to sidebar
                 if let presentedModal = presentedViewController {
                     presentedModal.dismiss(animated: false)
                 }
                 restorePrimaryToSidebar()
             }
         }
     }

     func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
         // Split view controller collapsed - we're now in compact mode
         // No action needed here as modal presentation is handled by togglePrimaryViewController
     }

     func splitViewControllerDidExpand(_ svc: UISplitViewController) {
         // Split view controller expanded - we're now in regular mode
         // Restore primary only if if we don't already have the primary set up in the sidebarNavigationController
         guard let primaryNavController = svc.viewController(for: .primary) as? UINavigationController,
               primaryNavController == sidebarNavigationController,
               primaryNavController.viewControllers.isEmpty else {
             return
         }
         restorePrimaryToSidebar()
     }
 }
