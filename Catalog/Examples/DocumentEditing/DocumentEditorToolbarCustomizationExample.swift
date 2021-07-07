//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DocumentEditorToolbarCustomizationExample: Example {

    override init() {
        super.init()
        title = "Document Editor Toolbar Customization"
        contentDescription = "Customize the new page button and remove all remaining buttons."
        category = .documentEditing
        priority = 1
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Let's create a new writable document every time we invoke the example for the
        // purpose of this example.
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)
        let pdfController = PDFViewController(document: document) {
            $0.overrideClass(PDFDocumentEditorToolbarController.self, with: FixedPageToolbarController.self)
            $0.overrideClass(PDFDocumentEditorToolbar.self, with: FixedPageToolbar.self)
        }

        // Immediately switch into document editor.
        pdfController.viewMode = .documentEditor

        return pdfController
    }

    // MARK: - Toolbar Controller

    private class FixedPageToolbarController: PDFDocumentEditorToolbarController {

        override init(toolbar: FlexibleToolbar) {
            super.init(toolbar: toolbar)

            // Replace the default action.
            let addPageButton = documentEditorToolbar.addPageButton
            addPageButton.removeTarget(nil, action: nil, for: .touchUpInside)
            addPageButton.addTarget(self, action: #selector(addNewFixedPage), for: .touchUpInside)
        }

        convenience override init(documentEditorToolbar: PDFDocumentEditorToolbar) {
            self.init(toolbar: documentEditorToolbar)
        }

        @objc func addNewFixedPage(_ sender: AnyObject) {
            guard let editor = documentEditor else {
                return
            }
            let pageSize = editor.pageSizeForPage(at: 0)
            let newPageConfiguration = PDFNewPageConfiguration(pageTemplate: PageTemplate(pageType: .tiledPatternPage, identifier: .grid5mm)) {
                $0.pageSize = pageSize
                $0.backgroundColor = UIColor.psc_secondarySystemBackground
            }
            editor.addPages(in: NSRange(location: 0, length: 1), with: newPageConfiguration)
        }
    }

    // MARK: - Toolbar

    private class FixedPageToolbar: PDFDocumentEditorToolbar {

        // An alternative would be to override the individual button properties and return nil.
        override func buttons(forWidth width: CGFloat) -> [ToolbarButton] {
            return super.buttons(forWidth: width).filter { button in
                // Keep the done button, add page button and spacers.
                button === doneButton || button === addPageButton || button.isFlexible == true
            }
        }
    }
}
