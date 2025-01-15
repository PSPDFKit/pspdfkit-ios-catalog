//
//  Copyright © 2019-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

@objc(PSCWindowCoordinator)
@MainActor class WindowCoordinator: NSObject {

    var window: UIWindow?

    var catalogViewController: CatalogViewController?
    var catalogStack: UINavigationController?

    @discardableResult func installCatalogStack(in window: UIWindow) -> CatalogViewController {
        self.window = window
        let catalogViewController = CatalogViewController()
        let catalogStack = PDFNavigationController(rootViewController: catalogViewController)
        catalogStack.navigationBar.prefersLargeTitles = true

        // We don’t want to show transparent toolbar backgrounds over a PDFViewController because PDF content might show underneath.
        // See https://www.nutrient.io/guides/ios/troubleshooting/user-interface/transparent-bar-backgrounds/
        catalogStack.toolbar.scrollEdgeAppearance = catalogStack.toolbar.standardAppearance
        catalogStack.toolbar.compactScrollEdgeAppearance = catalogStack.toolbar.standardAppearance

        catalogStack.delegate = self

        window.rootViewController = catalogStack
        window.makeKeyAndVisible()

        self.catalogViewController = catalogViewController
        self.catalogStack = catalogStack
        return catalogViewController
    }

    @discardableResult func handleOpenURL(_ url: URL?, options: [AnyHashable: Any]? = nil) -> Bool {
        guard let url else { return false }
        // Directly open the PDF.
        if url.isFileURL {
            var fileURL = url
            // UIApplicationOpenURLOptionsOpenInPlaceKey is set NO when file is already copied to Documents/Inbox by iOS
            let openInPlace = options?[UIApplication.OpenURLOptionsKey.openInPlace.rawValue] as? NSNumber

            if openInPlace == nil || openInPlace?.boolValue == false {
                if url.isLocatedInSamplesFolder {
                    // Directly open if document is in Samples folder.
                    fileURL = url
                } else if url.isLocatedInInbox {
                    // Move to Documents if already present in Inbox, otherwise copy.
                    fileURL = url.copyToDocumentDirectory(overwrite: true)
                    try? FileManager.default.removeItem(at: url)
                } else {
                    let success = url.startAccessingSecurityScopedResource()
                    defer {
                        if success {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    guard !FileManager.default.fileExists(atPath: url.path) else { return false }
                    fileURL = url.copyToDocumentDirectory(overwrite: true)
                }
            }

            presentViewControllerForDocument(at: fileURL)
            return true
        }
        return false
    }

    func presentViewControllerForDocument(at fileURL: URL) {
        let document = Document(url: fileURL)
        let pdfController = AdaptivePDFViewController(document: document)
        self.catalogStack?.popToRootViewController(animated: false)
        self.catalogStack?.pushViewController(pdfController, animated: false)
    }

    func openTabbedControllerForDocument(at fileURL: URL) {
        let tabbedController = TabbedExampleViewController()
        tabbedController.documents = [Document(url: fileURL)]
        catalogStack?.popToRootViewController(animated: false)
        catalogStack?.pushViewController(tabbedController, animated: false)
    }
}

extension WindowCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is CatalogViewController {
            navigationController.navigationBar.prefersLargeTitles = true
        }
    }
}
