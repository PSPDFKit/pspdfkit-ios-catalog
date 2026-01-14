//
//  Copyright © 2017-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CreateNoteFromTextSelectionExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Create Note from selected text"
        contentDescription = "Adds a new menu item that will create a note at the selected position with the text contents."
        category = .annotations
        priority = 60
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled
        let pdfController = PDFViewController(document: document, delegate: self)
        return pdfController
    }

    func pdfViewController(_ sender: PDFViewController, menuForText glyphs: GlyphSequence, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        // Create a custom action that adds a note for selected text.
        let createNoteAction = UIAction(title: "Create Note", image: UIImage(systemName: "plus.bubble")) { _ in
            UsernameHelper.ask(forDefaultAnnotationUsernameIfNeeded: sender) { _ in
                let noteAnnotation = NoteAnnotation()
                noteAnnotation.contents = glyphs.text
                noteAnnotation.pageIndex = pageView.pageIndex
                noteAnnotation.boundingBox = CGRect(x: glyphs.boundingBox.maxX, y: glyphs.boundingBox.minY, width: 32, height: 32)
                sender.document?.add(annotations: [noteAnnotation])
                pageView.presentComments(for: noteAnnotation)
            }
        }
        // Compose the final menu.
        return suggestedMenu.prepend([createNoteAction])
    }

}
