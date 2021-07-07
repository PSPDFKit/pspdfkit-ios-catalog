//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCCreateNoteFromTextSelectionExample.m' for the Objective-C version of this example.

class CreateNoteFromTextSelectionExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Create Note from selected text"
        contentDescription = "Adds a new menu item that will create a note at the selected position with the text contents."
        category = .annotations
        priority = 60
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        document.annotationSaveMode = .disabled
        let pdfController = PDFViewController(document: document, delegate: self)
        return pdfController
    }

    internal func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, forSelectedText selectedText: String, in textRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        if !selectedText.isEmpty {
            let createNoteMenu = MenuItem(title: "Create Note") {
                UsernameHelper.ask(forDefaultAnnotationUsernameIfNeeded: pdfController) { _ in
                    let noteAnnotation = NoteAnnotation()
                    noteAnnotation.pageIndex = pdfController.pageIndex
                    noteAnnotation.boundingBox = CGRect(x: textRect.maxX, y: textRect.origin.y, width: 32, height: 32)
                    noteAnnotation.contents = selectedText
                    pageView.presentationContext?.document?.add(annotations: [noteAnnotation])
                    pageView.selectionView.discardSelection(animated: false)
                    pageView.showNoteController(for: noteAnnotation, animated: true)
                }
            }
            return menuItems + [createNoteMenu]
        }
        return menuItems
    }
}
