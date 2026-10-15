//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// This example uses the following Nutrient features:
/// - Viewer
/// - Annotations
/// - Forms
///
/// See https://www.nutrient.io/sdk/ios for the complete list of Nutrient iOS SDK’s features.

class ElearningExample: IndustryExample {

    override init() {
        super.init()

        title = "E-Learning"
        contentDescription = "Shows how Nutrient can be configured for taking and grading an e-learning exam."
        category = .industryExamples
        priority = 1
        extendedDescription = """
        This example uses two documents: the student document and the teacher document. The documents are slightly different because the teacher document contains the solutions to the geography quiz.

        This example showcases how to transfer annotations, form field values, bookmarks, and the viewport from one document to another.

        It's more efficient to transfer the quiz data from the student document instead of sending the entire PDF file, which is useful for situations where data transfer over the internet is a constraint.
        """
        url = URL(string: "https://www.nutrient.io/blog/industry-solution-elearning-ios/")!
        image = UIImage(systemName: "books.vertical")
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        return ElearningPDFViewController(with: self)
    }
}

private class ElearningPDFViewController: PDFViewController, PDFViewControllerDelegate {

    private let studentDocument: Document
    private let teacherDocument: Document
    private var moreInfo: MoreInfoCoordinator!

    private lazy var segmentedControl = UISegmentedControl(items: ["Student", "Teacher"])

    init(with example: IndustryExample) {
        studentDocument = AssetLoader.writableDocument(for: .quizStudent, overrideIfExists: true)
        teacherDocument = AssetLoader.writableDocument(for: .quizTeacher, overrideIfExists: true)

        // Hide the document thumbnail bar at the bottom to reduce the space used by controls since we use that space for the teacher/student selection.
        let configuration = PDFConfiguration {
            $0.thumbnailBarMode = .none
            $0.shouldHideUserInterfaceOnPageChange = false
        }

        super.init(document: studentDocument, configuration: configuration)

        // Asynchronously pre-render and cache the documents.
        // See https://www.nutrient.io/guides/ios/getting-started/rendering-pdf-pages/#render-cache for more details.
        let pageSizes = [NSValue(cgSize: view.frame.size)]
        SDK.shared.cache.cacheDocument(studentDocument, withPageSizes: pageSizes)
        SDK.shared.cache.cacheDocument(teacherDocument, withPageSizes: pageSizes)

        // Customize the toolbar.
        // See https://www.nutrient.io/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        navigationItem.setRightBarButtonItems([annotationButtonItem, outlineButtonItem], for: .document, animated: false)
        navigationItem.setLeftBarButtonItems([moreInfo.barButton], for: .document, animated: false)
        navigationItem.leftItemsSupplementBackButton = true

        // Setup the segmented control.
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(switchDocument(_:)), for: .valueChanged)

        // Only show the bookmarks in the document info.
        // See https://www.nutrient.io/guides/ios/customizing-the-interface/customizing-the-available-document-information/ for more details.
        documentInfoCoordinator.availableControllerOptions = [.bookmarks]

        self.delegate = self

        setUpdateSettingsForBoundsChange { [weak self] _ in
            self?.updateNavigationBar()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBar()
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

    // MARK: Toolbar Visibility

    func pdfViewController(_ pdfController: PDFViewController, shouldShowUserInterface animated: Bool) -> Bool {
        updateToolbarVisibility(isUserInterfaceVisible: true, animated: animated)
        return true
    }

    func pdfViewController(_ pdfController: PDFViewController, shouldHideUserInterface animated: Bool) -> Bool {
        updateToolbarVisibility(isUserInterfaceVisible: false, animated: animated)
        return true
    }

    // MARK: Customization

    private func updateNavigationBar() {
        let availableWidth = view.bounds.inset(by: view.safeAreaInsets).width

        // Show more items on wide screens. 550 is the minimum width needed to show 9 items including the close button and the segmented control.
        // Move the segmented control to the navigation bar if space is available, otherwise move to the bottom toolbar and make it visible.
        if shouldUseNavigationBar(forWidth: availableWidth) {
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, searchButtonItem, outlineButtonItem, activityButtonItem, annotationButtonItem], for: .document, animated: false)
            toolbarItems = []
            navigationItem.titleView = segmentedControl
        } else {
            // reduce the number of items if the navigation bar is really size constrained
            if availableWidth < 400 {
                navigationItem.setRightBarButtonItems([thumbnailsButtonItem, outlineButtonItem, annotationButtonItem], for: .document, animated: false)
            } else {
                navigationItem.setRightBarButtonItems([thumbnailsButtonItem, searchButtonItem, outlineButtonItem, activityButtonItem, annotationButtonItem], for: .document, animated: false)
            }
            navigationItem.titleView = nil
            toolbarItems = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(customView: segmentedControl),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            ]
        }
        updateToolbarVisibility(isUserInterfaceVisible: isUserInterfaceVisible, animated: false)
    }

    private func updateToolbarVisibility(isUserInterfaceVisible: Bool, animated: Bool) {
        let availableWidth = view.bounds.inset(by: view.safeAreaInsets).width

        // Hide the toolbar for large screen sizes as all items and the segmented control is presented in the navigation bar.
        // For constrained screen sizes the segmented control is presented in the bottom toolbar, show the toolbar if the PDF user interface is visible.
        if shouldUseNavigationBar(forWidth: availableWidth) {
            self.navigationController?.setToolbarHidden(true, animated: animated)
        } else {
            self.navigationController?.setToolbarHidden(!isUserInterfaceVisible, animated: animated)
        }
    }

    private func shouldUseNavigationBar(forWidth availableWidth: CGFloat) -> Bool {
        // Use a toolbar for the segmented control if there is not enough available space in the navigation bar
        // On Mac Catalyst titleView doesn't show the segmented control so we always show the segmented control in the toolbar
        return availableWidth > 550 && !ProcessInfo.processInfo.isMacCatalystApp
    }

    // MARK: Private

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
        if let viewState {
            applyViewState(viewState, animateIfPossible: false)
        }
    }
}
