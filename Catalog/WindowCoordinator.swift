//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit
import PSPDFKit

@objc(PSCWindowCoordinator)
class WindowCoordinator: NSObject {

    var window: UIWindow?

    var catalog: CatalogViewController?
    var catalogStack: UINavigationController?

    @discardableResult func installCatalogStack(in window: UIWindow) -> CatalogViewController {
        self.window = window
        let catalog = CatalogViewController(style: .insetGrouped)
        let catalogStack = PDFNavigationController(rootViewController: catalog)
        catalogStack.navigationBar.prefersLargeTitles = true
        catalogStack.delegate = self

        catalog.window = window
        window.rootViewController = catalogStack
        window.makeKeyAndVisible()

        self.catalog = catalog
        self.catalogStack = catalogStack
        return catalog
    }

    @discardableResult func handleOpenURL(_ url: URL?, options: [AnyHashable: Any]? = nil) -> Bool {
        guard let url = url else { return false }
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
        let pdfController = viewController(for: document)
        self.catalogStack?.popToRootViewController(animated: false)
        self.catalogStack?.pushViewController(pdfController, animated: false)
    }

    func viewController(for document: Document) -> PDFViewController {
        let pdfController = PDFViewController(document: document)
        pdfController.navigationItem.setRightBarButtonItems([pdfController.thumbnailsButtonItem, pdfController.annotationButtonItem, pdfController.outlineButtonItem, pdfController.searchButtonItem], for: .document, animated: false)
        return pdfController
    }

    func openTabbedControllerForDocument(at fileURL: URL) {
        let tabbedController = TabbedExampleViewController()
        tabbedController.documents = [Document(url: fileURL)]
        catalogStack?.popToRootViewController(animated: false)
        catalogStack?.pushViewController(tabbedController, animated: false)
    }

    @discardableResult func openShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("Opening a shortcut item: \(shortcutItem)")

        self.catalogStack?.popToRootViewController(animated: false)
        guard let catalog = self.catalog else { return false }
        return catalog.openExample(withType: shortcutItem.type)
    }
}

extension WindowCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is CatalogViewController {
            navigationController.navigationBar.prefersLargeTitles = true
        }
    }
}
