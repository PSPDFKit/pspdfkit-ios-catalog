//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class LargeNoteControllerFontExample: Example {

    override init() {
        super.init()

        title = "Custom Font for Comments"
        contentDescription = "Shows how to customize the font for comments in the NoteAnnotationViewController."
        category = .viewCustomization
        priority = 89
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = PDFViewController(document: document) {
            $0.overrideClass(NoteAnnotationViewController.self, with: LargeFontNoteAnnotationViewController.self)
        }

        // We create the appearance rule on the custom subclass to avoid changing the note controllers in other examples.
        UITextView.appearance(whenContainedInInstancesOf: [LargeFontNoteAnnotationViewController.self]).font = UIFont(name: "Noteworthy", size: 30)
        UITextView.appearance(whenContainedInInstancesOf: [LargeFontNoteAnnotationViewController.self]).textColor = UIColor.systemGreen

        return pdfController
    }
}

// Custom empty subclass of the NoteAnnotationViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
private class LargeFontNoteAnnotationViewController: NoteAnnotationViewController {
    override func update(_ textView: UITextView) {
        // Possible to set the color here, but it's even cleaner to use UIAppearance rules (see above).
        // textView.font = UIFont(name: "Futura", size: 40)
        // textView.textColor = .brown
    }
}
