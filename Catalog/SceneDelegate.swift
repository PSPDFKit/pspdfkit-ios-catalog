//
//  Copyright © 2019-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    let windowCoordinator = WindowCoordinator()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Don't create a new scene for external displays.
        // Use default screen mirroring, and let PSPDFScreenController handle.
        guard session.role == .windowApplication,
              let windowScene = scene as? UIWindowScene else { return }
        // Disable the Catalyst titlebar separator to remove the shadow line that overlaps document tabs in multi-document controllers.
        #if targetEnvironment(macCatalyst)
            windowScene.titlebar?.separatorStyle = .none
        #endif
        let window = UIWindow(windowScene: windowScene)
        let catalog = windowCoordinator.installCatalogStack(in: window)

        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if userActivity.isOpenExampleActivity {
                catalog.restoreUserActivityState(userActivity)
            } else if userActivity.isOpenDocumentActivity {
                if let fileURL = userActivity.fileURL {
                    NotificationCenter.default.post(name: .PSCDocumentOpenedInNewScene, object: nil, userInfo: ["documentURL": fileURL])
                    windowCoordinator.openTabbedControllerForDocument(at: fileURL)
                }
            }
        }
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        scene.userActivity
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for urlContext in URLContexts {
            windowCoordinator.handleOpenURL(urlContext.url)
        }
    }
}

public extension NSNotification.Name {
    static let PSCDocumentOpenedInNewScene = NSNotification.Name("PSCDocumentOpenedInNewScene")
}
