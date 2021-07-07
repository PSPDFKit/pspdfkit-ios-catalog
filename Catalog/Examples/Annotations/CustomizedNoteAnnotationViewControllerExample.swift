//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomizedNoteAnnotationViewControllerExample: Example {

    override init() {
        super.init()

        title = "Customized PSPDFNoteAnnotationViewController"
        category = .annotations
        priority = 400
        wantsModalPresentation = true
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let noteAnnotation = NoteAnnotation()
        // width/height will be ignored for note annotations.
        noteAnnotation.boundingBox = CGRect(x: 100, y: 100, width: 32, height: 32)
        noteAnnotation.contents = "This is a sample note."

        let noteViewController = CustomPSPDFNoteAnnotationViewController(annotation: noteAnnotation)
        noteViewController.backgroundView.backgroundColor = .red
        noteViewController.commentBackgroundColor = .yellow
        noteViewController.showsTimestamps = false
        noteViewController.showsAuthorName = false

        return noteViewController
    }

    class CustomPSPDFNoteAnnotationViewController: NoteAnnotationViewController {

        override func viewDidLoad() {
            super.viewDidLoad()
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        }

        @objc func dismissModal() {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
