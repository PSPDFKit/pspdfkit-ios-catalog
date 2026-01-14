//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// This example shows how to add ‘discrete’ annotations from a menu so the toolbar is only for drawing.
///
/// Many annotation types like rectangles, notes, text and signatures can be created as a discrete
/// step so can be inserted efficiently from a menu. This allows the annotation toolbar to be
/// simplified by making it only contains tools that put the UI into a mode (mostly for drawing).
///
/// You could consider combining this with the tool picker from PencilKit shown in `PencilKitToolPickerExample`.
class AnnotationInsertMenuExample: Example {

    override init() {
        super.init()

        title = "Annotation Insert Menu"
        contentDescription = "Add annotations from a menu so the toolbar is only for drawing."
        category = .barButtons
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        let controller = PDFViewController(document: document) {
            $0.signatureStore = KeychainSignatureStore()
        }

        let insertAnnotationButtonItem = UIBarButtonItem(systemItem: .add, menu: UIMenu(children: [
            UIAction(title: "Shape", image: UIImage(systemName: "square.on.circle")) { [unowned self, unowned controller] action in
                let shapesViewController = ShapesGridViewController { [unowned self, unowned controller] annotation in
                    self.add(annotation: annotation, in: controller)
                }
                let navigationController = UINavigationController(rootViewController: shapesViewController)
                navigationController.modalPresentationStyle = .popover
                controller.present(navigationController, animated: true, sender: action.sender)
            },
            UIAction(title: "Signature", image: PSPDFKit.SDK.imageNamed(Annotation.Tool.signature.rawValue.lowercased())) { [unowned controller] action in
                controller.annotationStateManager.toggleSignatureController(action.sender)
            },
            UIAction(title: "Note", image: PSPDFKit.SDK.imageNamed(Annotation.Tool.note.rawValue.lowercased())) { [unowned self, unowned controller] _ in
                self.addNote(in: controller)
            },
            UIAction(title: "Text", image: PSPDFKit.SDK.imageNamed(Annotation.Tool.freeText.rawValue.lowercased())) { [unowned self, unowned controller] _ in
                self.addText(in: controller)
            },
            UIAction(title: "Image", image: PSPDFKit.SDK.imageNamed(Annotation.Tool.image.rawValue.lowercased())) { [unowned controller] action in
                controller.annotationStateManager.toggleImagePickerController(action.sender)
            },
            UIAction(title: "Stamp", image: PSPDFKit.SDK.imageNamed(Annotation.Tool.stamp.rawValue.lowercased())) { [unowned controller] action in
                controller.annotationStateManager.toggleStampController(action.sender)
            },
            UIAction(title: "Saved Annotation", image: PSPDFKit.SDK.imageNamed(Annotation.Tool.savedAnnotations.rawValue.lowercased())) { [unowned controller] action in
                controller.annotationStateManager.toggleSavedAnnotations(action.sender)
            },
        ]))

        controller.navigationItem.setRightBarButtonItems([controller.thumbnailsButtonItem, controller.activityButtonItem, controller.searchButtonItem, insertAnnotationButtonItem, controller.annotationButtonItem], for: .document, animated: false)

        // Set up the simplified annotation toolbar with only modal tools.
        let drawing = AnnotationToolConfiguration.ToolItem(type: .ink, variant: .inkPen, configurationBlock: AnnotationToolConfiguration.ToolItem.inkConfigurationBlock())
        let freeformHighlight = AnnotationToolConfiguration.ToolItem(type: .ink, variant: .inkHighlighter, configurationBlock: AnnotationToolConfiguration.ToolItem.inkConfigurationBlock())
        let eraser = AnnotationToolConfiguration.ToolItem(type: .eraser)
        let polyline = AnnotationToolConfiguration.ToolItem(type: .polyLine)
        let polygon = AnnotationToolConfiguration.ToolItem(type: .polygon)
        let selectionTool = AnnotationToolConfiguration.ToolItem(type: .selectionTool)
        controller.annotationToolbarController!.annotationToolbar.configurations = [
            // No tool grouping when there is enough space.
            AnnotationToolConfiguration(annotationGroups: [
                AnnotationToolConfiguration.ToolGroup(items: [drawing]),
                AnnotationToolConfiguration.ToolGroup(items: [freeformHighlight]),
                AnnotationToolConfiguration.ToolGroup(items: [eraser]),
                AnnotationToolConfiguration.ToolGroup(items: [polyline]),
                AnnotationToolConfiguration.ToolGroup(items: [polygon]),
                AnnotationToolConfiguration.ToolGroup(items: [selectionTool]),
            ]),
            // Compress some tools into groups when space is limited.
            AnnotationToolConfiguration(annotationGroups: [
                AnnotationToolConfiguration.ToolGroup(items: [drawing, freeformHighlight]),
                AnnotationToolConfiguration.ToolGroup(items: [eraser]),
                AnnotationToolConfiguration.ToolGroup(items: [polyline, polygon]),
                AnnotationToolConfiguration.ToolGroup(items: [selectionTool]),
            ]),
            // Last resort with only two groups for iPad at 320 pt wide.
            AnnotationToolConfiguration(annotationGroups: [
                AnnotationToolConfiguration.ToolGroup(items: [drawing, freeformHighlight]),
                AnnotationToolConfiguration.ToolGroup(items: [eraser, polyline, polygon, selectionTool]),
            ]),
        ]

        return controller
    }

    private func addNote(in pdfViewController: PDFViewController) {
        let noteAnnotation = NoteAnnotation()
        noteAnnotation.boundingBox = CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
        SDK.shared.styleManager.lastUsedStyle(forKey: .init(tool: .note))?.apply(to: noteAnnotation)

        guard let pageView = add(annotation: noteAnnotation, in: pdfViewController) else { return }

        pageView.presentComments(for: noteAnnotation)
    }

    private func addText(in pdfViewController: PDFViewController) {
        let freeTextAnnotation = FreeTextAnnotation()
        freeTextAnnotation.boundingBox = CGRect(origin: .zero, size: CGSize(width: 10, height: 40))
        SDK.shared.styleManager.lastUsedStyle(forKey: .init(tool: .freeText))?.apply(to: freeTextAnnotation)

        guard let pageView = add(annotation: freeTextAnnotation, in: pdfViewController) else { return }

        /*
         After adding the annotation to the document, select it, grab the annotation view, and tell
         it to begin editing, so that the keyboard comes up. The way we set up the PDFViewController,
         we know that the view returned by `annotationView(for:)` is a `FreeTextAnnotationView`.
         Depending on your configuration, this need not be the case.
         */
        let annotationView = pageView.annotationView(for: freeTextAnnotation) as! FreeTextAnnotationView
        annotationView.beginEditing()
    }

    /// Adds the annotation to the current document in the center of the visible page. Returns the page view the annotation was added to, or nil if the annotation couldn’t be added.
    @discardableResult private func add(annotation: Annotation, in pdfViewController: PDFViewController) -> PDFPageView? {
        guard let document = pdfViewController.document else { return nil }
        let pageIndex = pdfViewController.pageIndex
        guard pageIndex != NSNotFound, let pageView = pdfViewController.pageViewForPage(at: pdfViewController.pageIndex) else { return nil }

        // Put the new annotation in the center of the current page.
        annotation.pageIndex = pageIndex
        let pageSize = document.pageInfoForPage(at: pageIndex)!.size
        let initialSize = annotation.boundingBox.size
        annotation.boundingBox = CGRect(x: 0.5 * (pageSize.width - initialSize.width), y: 0.5 * (pageSize.height - initialSize.height), width: initialSize.width, height: initialSize.height)

        document.undoController.recordCommand(named: "Add Annotation", adding: [annotation]) {
            document.add(annotations: [annotation])
        }
        pageView.selectedAnnotations = [annotation]
        return pageView
    }

}

/// Shows a grid of shape annotations the user can select to add to the document.
private class ShapesGridViewController: UIViewController, AnnotationGridViewControllerDataSource, AnnotationGridViewControllerDelegate {

    private let annotationGridViewController = AnnotationGridViewController()

    private lazy var annotationSets: [AnnotationSet] = {
        let styleManager = SDK.shared.styleManager

        let arrow = LineAnnotation(point1: CGPoint(x: 0, y: 0), point2: CGPoint(x: 100, y: 100))
        styleManager.lastUsedStyle(forKey: .init(tool: .line, variant: .lineArrow))?.apply(to: arrow)

        let line = LineAnnotation(point1: CGPoint(x: 0, y: 0), point2: CGPoint(x: 100, y: 100))
        styleManager.lastUsedStyle(forKey: .init(tool: .line))?.apply(to: line)

        let rectangle = SquareAnnotation()
        rectangle.boundingBox = CGRect(origin: .zero, size: CGSize(width: 120, height: 90))
        styleManager.lastUsedStyle(forKey: .init(tool: .square))?.apply(to: rectangle)

        let ellipse = CircleAnnotation()
        ellipse.boundingBox = CGRect(origin: .zero, size: CGSize(width: 120, height: 90))
        styleManager.lastUsedStyle(forKey: .init(tool: .circle))?.apply(to: ellipse)

        return [arrow, line, rectangle, ellipse].map {
            AnnotationSet(annotations: [$0], copyAnnotations: false)
        }
    }()

    private let didSelectAnnotation: (Annotation) -> Void

    init(didSelectAnnotation: @escaping (Annotation) -> Void) {
        self.didSelectAnnotation = didSelectAnnotation

        super.init(nibName: nil, bundle: nil)

        annotationGridViewController.dataSource = self
        annotationGridViewController.delegate = self

        addChild(annotationGridViewController)
        annotationGridViewController.didMove(toParent: self)

        self.title = "Shapes"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(annotationGridViewController.view)

        annotationGridViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            annotationGridViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            annotationGridViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            annotationGridViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            annotationGridViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func numberOfSections(in annotationGridController: AnnotationGridViewController) -> Int {
        1
    }

    func annotationGridViewController(_ annotationGridController: AnnotationGridViewController, numberOfAnnotationsInSection section: Int) -> Int {
        annotationSets.count
    }

    func annotationGridViewController(_ annotationGridController: AnnotationGridViewController, annotationSetFor indexPath: IndexPath) -> AnnotationSet {
        annotationSets[indexPath.row]
    }

    func annotationGridViewController(_ annotationGridController: AnnotationGridViewController, didSelect annotationSet: AnnotationSet) {
        // It’s important to copy the annotation objects like this so they have different UUIDs when the same shape is added multiple times.
        // This requires using private API. In general, setting the UUID like this is unsupported. We don’t guarantee that this will continue working.
        // It works in this specific scenario where we copy an annotation not added to a document and set the UUID immediately after that.
        let copiedAnnotation = annotationSet.annotations[0].copy() as! Annotation
        copiedAnnotation.setValue(UUID().uuidString, forKey: "uuid")
        didSelectAnnotation(copiedAnnotation)
        dismiss(animated: true)
    }

}
