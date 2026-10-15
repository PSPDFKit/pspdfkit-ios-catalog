//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKitUI

class RemoveWritingToolsMenuItemExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Remove Writing Tools, Look Up, Translate, and Search Web menu items"
        contentDescription = "Remove the Apple Intelligence Writing Tools, Look Up, Translate, and Search Web commands from the text selection menu."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let controller = AdaptivePDFViewController(document: document)
        controller.delegate = self
        return controller
    }

    func pdfViewController(_ sender: PDFViewController, menuForText glyphs: GlyphSequence, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        // Remove Look Up, Translate, and Search Web. Apple bundles all three under the
        // .lookup submenu and doesn't expose separate public identifiers for each.
        let newMenu = suggestedMenu.reject(menus: [.lookup], actions: [])
#if os(iOS)
        if #available(iOS 18.2, *) {
            return newMenu.filterCommands { command in
                // Remove Writing Tools (Apple Intelligence).
                command.action != #selector(UIResponder.showWritingTools(_:))
            }
        }
#endif
        return newMenu
    }
}

private extension UIMenu {

    /// Recursively filters UICommands in the menus. I.e. removes commands where the predicate return false.
    func filterCommands(_ predicate: (UICommand) -> Bool) -> UIMenu {
        replacingChildren(children.compactMap { element in
            if let command = element as? UICommand {
                if predicate(command) {
                    return element
                } else {
                    return nil
                }
            } else if let menu = element as? UIMenu {
                // Filter children of submenus recursively.
                return menu.filterCommands(predicate)
            } else {
                return element
            }
        })
    }

}
