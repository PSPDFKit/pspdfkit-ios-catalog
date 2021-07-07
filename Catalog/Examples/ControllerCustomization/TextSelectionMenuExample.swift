//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class TextSelectionMenuExample: Example, PDFViewControllerDelegate {
    override init() {
        super.init()

        title = "Custom Text Selection Menu"
        contentDescription = "Add a menu item to search the web for selected text using PDFViewControllerDelegate."
        category = .controllerCustomization
        priority = 100
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        let pdfViewController = PDFViewController(document: document)
        pdfViewController.delegate = self
        return pdfViewController
    }

    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, forSelectedText selectedText: String, in textRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        guard let encodedText = selectedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return menuItems
        }

        var newMenuItems = menuItems

        // Remove the regular Define and Search menu items.
        newMenuItems = newMenuItems.filter {
            $0.identifier != TextMenu.define.rawValue && $0.identifier != TextMenu.search.rawValue
        }

        // Add a menu item to search the web for the selected text using Ecosia, a search engine that plants trees.
        let webSearchItem = MenuItem(title: "Search Web") {
            UIApplication.shared.open(URL(string: "https://www.ecosia.org/search?q=\(encodedText)")!)

        }
        newMenuItems.append(webSearchItem)

        return newMenuItems
    }
}
