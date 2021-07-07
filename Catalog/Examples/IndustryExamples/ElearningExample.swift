//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// This example uses the following PSPDFKit features:
/// - Viewer
/// - Annotations
/// - Forms
///
/// See https://pspdfkit.com/pdf-sdk/ios/ for the complete list of features for PSPDFKit for iOS.

class ElearningExample: IndustryExample {

    override init() {
        super.init()

        title = "E-Learning"
        contentDescription = "Shows how PSPDFKit can be configured for taking and grading an e-learning exam."
        category = .industryExamples
        priority = 1
        extendedDescription = """
        This example uses two documents: the student document and the teacher document. The documents are slightly different because the teacher document contains the solutions to the geography quiz.

        This example showcases how to transfer annotations, form field values, bookmarks, and the viewport from one document to another.

        It's more efficient to transfer the quiz data from the student document instead of sending the entire PDF file, which is useful for situations where data transfer over the internet is a constraint.
        """
        url = URL(string: "https://pspdfkit.com/blog/2021/industry-solution-elearning-ios/")!
        if #available(iOS 14.0, *) {
            image = UIImage(systemName: "books.vertical")
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        return ElearningPDFViewController(with: self)
    }
}

private class ElearningPDFViewController: PDFViewController {

    private let studentDocument: Document
    private let teacherDocument: Document
    private var moreInfo: MoreInfoCoordinator!

    init(with example: IndustryExample) {
        studentDocument = AssetLoader.writableDocument(for: .student, overrideIfExists: true)
        teacherDocument = AssetLoader.writableDocument(for: .teacher, overrideIfExists: true)

        super.init(document: studentDocument, configuration: nil)

        // Asynchronously pre-render and cache the documents.
        // See https://pspdfkit.com/guides/ios/getting-started/rendering-pdf-pages/#the-cache for more details.
        let pageSizes = [NSValue(cgSize: view.frame.size)]
        SDK.shared.cache.cacheDocument(studentDocument, withPageSizes: pageSizes)
        SDK.shared.cache.cacheDocument(teacherDocument, withPageSizes: pageSizes)

        // Customize the toolbar.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        navigationItem.setRightBarButtonItems([annotationButtonItem, outlineButtonItem], for: .document, animated: false)
        navigationItem.setLeftBarButtonItems([moreInfo.barButton], for: .document, animated: false)
        navigationItem.leftItemsSupplementBackButton = true

        // Add the segmented control.
        let segmentedControl = UISegmentedControl(items: ["Student", "Teacher"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(switchDocument(_:)), for: .valueChanged)
        navigationItem.titleView = segmentedControl

        // Only show the bookmarks in the document info.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-available-document-information/ for more details.
        documentInfoCoordinator.availableControllerOptions = [.bookmarks]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

    // MARK: Private

    // swiftlint:disable cyclomatic_complexity
    @objc private func switchDocument(_ sender: UISegmentedControl) {

        guard let currentDocument = document else {
            print("The current document needs to be set.")
            return
        }

        // Cache the current view state
        let viewState = self.viewState

        // Cache the annotations from the current document.
        let allTypesButForms = Annotation.Kind.all.subtracting(.widget)
        let annotations = currentDocument.allAnnotations(of: allTypesButForms).flatMap({ $0.value })

        // Cache all the form values from the current document.
        var forms = [FormElement]()
        if let formParser = currentDocument.formParser {
            forms = formParser.forms
        }

        // Cache all the bookmarks from the current document.
        let bookmarks = currentDocument.bookmarks

        // The target document.
        var targetDocument: Document
        if currentDocument == studentDocument {
            targetDocument = teacherDocument
        } else {
            targetDocument = studentDocument
        }

        // Delete all existing annotations from the target document,
        // since we'll be re-adding them from the current document.
        let previousAnnotations = targetDocument.allAnnotations(of: allTypesButForms).flatMap { _, annotationsOnPage in
            annotationsOnPage
        }
        targetDocument.remove(annotations: previousAnnotations)

        // Delete existing bookmarks from the target document
        // since we'll be re-adding them from the current document.
        let existingBookmarks = targetDocument.bookmarks
        for bookmark in existingBookmarks {
            targetDocument.bookmarkManager?.removeBookmark(bookmark)
        }

        // Re-add a copy of the annotations from the current document.
        let newAnnotations = annotations.compactMap { annotation -> Annotation? in
            let copiedAnnotation = annotation.copy() as? Annotation
            return copiedAnnotation
        }
        targetDocument.add(annotations: newAnnotations)

        // Transfer form element values from the previous document to the new one.
        for index in 0..<forms.count {
            // Forms are identical between the two documents, so we have the guarantee that we have the same form element at a given index.
            let previousFormElement = forms[index]
            let newFormElement = targetDocument.formParser?.forms[index]
            if let previousButtomFormElement = previousFormElement as? ButtonFormElement,
               let newButtonFormElement = newFormElement as? ButtonFormElement {
                if previousButtomFormElement.isSelected {
                    newButtonFormElement.select()
                } else {
                    newButtonFormElement.deselect()
                }
            }
            if let previousChoiceFormElement = previousFormElement as? ChoiceFormElement,
               let newFormChoiceElement = newFormElement as? ChoiceFormElement {
                newFormChoiceElement.selectedIndices = previousChoiceFormElement.selectedIndices
            }
            if previousFormElement is TextFieldFormElement {
                newFormElement?.contents = previousFormElement.contents
            }
        }

        // Transfer the bookmarks from the current document.
        for bookmark in bookmarks {
            targetDocument.bookmarkManager?.addBookmark(bookmark)
        }

        // Change the PDF view controller's document.
        document = targetDocument

        // Restore the view state
        if let viewState = viewState {
            applyViewState(viewState, animateIfPossible: false)
        }
    }
}
