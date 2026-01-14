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
/// - Indexed Search
/// - Replies
///
/// See https://www.nutrient.io/sdk/ios for the complete list of Nutrient iOS SDK’s features.

class ConstructionExample: IndustryExample {

    override init() {
        super.init()

        title = "Construction"
        contentDescription = "Shows how to configure Nutrient to display a building floor plan."
        category = .industryExamples
        priority = 5
        extendedDescription = """
        This example shows how to customize the annotation toolbar for the construction industry by adding the following custom tools:

        1. The drop pin tool — this lets the user create tasks on specific areas of the building floor plan.
        2. The file attachment tool — this lets the user attach documents to the floor plan document.
        """
        url = URL(string: "https://www.nutrient.io/blog/industry-solution-construction-ios/")!
        image = UIImage(systemName: "building.2.crop.circle")
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        return ConstructionPDFViewController(with: self)
    }
}

/// Custom PDF view controller class.
private class ConstructionPDFViewController: PDFViewController, PDFViewControllerDelegate, PDFDocumentPickerControllerDelegate {

    /// Document picker shown while adding a file annotation.
    var documentPickerController: PDFDocumentPickerController?

    /// The point where the page view is long pressed to show the menu.
    /// Used to calculate the file annotation's bounding box.
    var longPressedPoint: CGPoint?

    /// Bar button item used for showing annotation list.
    private lazy var annotationListButtonItem: UIBarButtonItem = UIBarButtonItem(image: SDK.imageNamed("document_annotations")!, style: outlineButtonItem.style, target: outlineButtonItem.target, action: outlineButtonItem.action)

    /// Used for showing the more info alert.
    private var moreInfo: MoreInfoCoordinator!

    init(with example: IndustryExample) {
        let document = AssetLoader.writableDocument(for: .floorPlan, overrideIfExists: false)
        document.title = "Building Floor Plan"
        document.overrideClass(StampAnnotation.self, with: PinStampAnnotation.self)

        let emailConfiguration = DocumentSharingConfiguration.defaultConfiguration(forDestination: .email).configurationUpdated {
            $0.destination = .email
            $0.fileFormatOptions = [.PDF, .image]
            $0.annotationOptions = [.embed, .remove]
            $0.pageSelectionOptions = [.all]
        }

        let configuration = PDFConfiguration {
            // Register the custom subclass of `AnnotationToolbar` to customize the annotation toolbar.
            $0.overrideClass(AnnotationToolbar.self, with: ConstructionAnnotationToolbar.self)

            // Customize the sharing experience if available.
            if MFMailComposeViewController.canSendMail() {
                $0.sharingConfigurations = [emailConfiguration]
            }

            // Miscellaneous configuration options.
            $0.backgroundColor = UIColor.psc_secondarySystemBackground
            $0.thumbnailBarMode = .none
            $0.spreadFitting = .fit
            $0.isPageLabelEnabled = false
            $0.documentLabelEnabled = .NO
            $0.isTextSelectionEnabled = false

            // We handle the navigation bar title manually.
            $0.allowToolbarTitleChange = false
        }

        super.init(document: document, configuration: configuration)

        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        delegate = self

        documentPickerController = PDFDocumentPickerController(directory: "/Bundle/Samples", includeSubdirectories: true, library: SDK.shared.library)
        documentPickerController?.delegate = self

        // Configure custom default color presets.
        // See https://www.nutrient.io/guides/ios/annotations/customizing-presets/ for more details.
        let presets = [
            ColorPreset(color: .red),
            ColorPreset(color: .black),
            ColorPreset(color: .green),
            ColorPreset(color: .blue)
        ]
        setDefault(colorPresets: presets, defaultColor: .red)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(document: Document?, configuration: PDFConfiguration?) {
        super.init(document: document, configuration: configuration)
        moreInfo = MoreInfoCoordinator(with: ConstructionExample(), presentationContext: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Customize the navigation bar.
        // See https://www.nutrient.io/guides/ios/user-interface/main-toolbar for more details.
        navigationItem.leftBarButtonItems = [moreInfo.barButton, toggleAnnotationVisibilityBarButtonItem]
        navigationItem.leftItemsSupplementBackButton = true

        // Only show the annotations list in the document info.
        // See https://www.nutrient.io/guides/ios/customizing-the-interface/customizing-the-available-document-information/ for more details.
        documentInfoCoordinator.availableControllerOptions = [.annotations]

        // Only support the right position for the annotation toolbar.
        let annotationToolbar = annotationToolbarController!.annotationToolbar
        annotationToolbar.supportedToolbarPositions = .right
        annotationToolbar.toolbarPosition = .right
        annotationToolbar.isDragEnabled = false

        // Use white buttons and a black background for the annotation toolbar.
        if #available(iOS 26, *) {
            // On iOS 26 we need to set the bar tint color which tints the glass background.
            annotationToolbar.barTintColor = UIColor(white: 0.2, alpha: 0.98)
        } else {
            // On older iOS versions we use the UIAppearance API
            // (which doesn't do anything anymore on iOS 26).
            let appearance = UIToolbarAppearance()
            appearance.backgroundColor = UIColor(white: 0.2, alpha: 0.98)
            annotationToolbar.standardAppearance = appearance
            annotationToolbar.compactAppearance = appearance
        }
        annotationToolbar.tintColor = UIColor(white: 0.95, alpha: 0.98)

        // Setup a tap gesture recognizer that adds a pin annotation to the page if the pin annotation tool is selected.
        let addPinAnnotationGestureRecognizer = UITapGestureRecognizer()
        addPinAnnotationGestureRecognizer.addTarget(self, action: #selector(addPinAnnotationGestureRecognizerDidChangeState))

        // Make it work simultaneously with all built-in interaction components.
        interactions.allInteractions.allowSimultaneousRecognition(with: addPinAnnotationGestureRecognizer)
        // Add the gesture recognizer to the document view controller's view.
        documentViewController?.view.addGestureRecognizer(addPinAnnotationGestureRecognizer)

        setUpdateSettingsForBoundsChange { [weak self] _ in
            self?.updateNavigationBar()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

    // MARK: Customization

    private func updateNavigationBar() {
        let availableWidth = view.bounds.inset(by: view.safeAreaInsets).width

        // Show more items on wide screens. 440 is the minimum width needed to show 6 items including the back button.
        // Hide the title in the navigation bar if space is constrained and enable the floating document label in the document.
        if availableWidth > 440 {
            navigationItem.rightBarButtonItems = [activityButtonItem, annotationButtonItem, annotationListButtonItem]
            updateConfiguration {
                $0.documentLabelEnabled = .NO
            }
            navigationItem.title = document?.title
        } else {
            navigationItem.rightBarButtonItems = [annotationButtonItem, annotationListButtonItem]
            updateConfiguration {
                $0.documentLabelEnabled = .YES
            }
            navigationItem.title = nil
        }
    }

    // MARK: FlexibleToolbarContainerDelegate

    override func flexibleToolbarContainerWillShow(_ container: FlexibleToolbarContainer) {
        // If the annotations visibility is disabled, we force enable it when annotation toolbar becomes visible.
        if toggleAnnotationVisibilityBarButtonItem.title == "show" {
            didTapToggleAnnotationVisibilityBarButtonItem(toggleAnnotationVisibilityBarButtonItem)
        }
    }

    override func flexibleToolbarContainerDidHide(_ container: FlexibleToolbarContainer) {
        if let annotationToolbar = annotationToolbarController?.annotationToolbar as? ConstructionAnnotationToolbar {
            annotationToolbar.deselectAllTools()
        }
    }

    override func flexibleToolbarContainerContentRect(_ container: FlexibleToolbarContainer, for position: FlexibleToolbar.Position) -> CGRect {
        if [.pad, .mac].contains(container.traitCollection.userInterfaceIdiom) {
            let estimatedHeight: CGFloat = container.traitCollection.userInterfaceIdiom == .pad ? 600 : 456
            let safeArea = view.bounds.inset(by: view.safeAreaInsets).inset(by: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
            return CGRect(x: safeArea.minX, y: safeArea.minY, width: safeArea.width, height: min(estimatedHeight, safeArea.height))
        } else {
            return super.flexibleToolbarContainerContentRect(container, for: position)
        }
    }

    // MARK: Private

    private lazy var toggleAnnotationVisibilityBarButtonItem: UIBarButtonItem = {
        let toggleAnnotationVisibility = UIBarButtonItem(image: UIImage(namedInCatalog: "hide"), style: .plain, target: self, action: #selector(didTapToggleAnnotationVisibilityBarButtonItem))
        toggleAnnotationVisibility.title = "hide"
        return toggleAnnotationVisibility
    }()

    @objc func didTapToggleAnnotationVisibilityBarButtonItem(_ sender: UIBarButtonItem) {
        // Let link annotations be always visible.
        if sender.title == "hide" {
            setVisibleAnnotationTypes(.link)
            sender.title = "show"
            sender.image = UIImage(namedInCatalog: "show")
        } else {
            setVisibleAnnotationTypes(.all)
            sender.title = "hide"
            sender.image = UIImage(namedInCatalog: "hide")
        }
    }

    private func setVisibleAnnotationTypes(_ types: Annotation.Kind) {
        // Update the render types.
        document?.renderAnnotationTypes = types
        // Clear the cache so that pages are re-rendered once updated.
        PSPDFKit.SDK.shared.cache.remove(for: document)
        for pageView in visiblePageViews {
            pageView.updateAnnotationViews(animated: false)
            pageView.update()
        }
    }

    private func setDefault(colorPresets: [ColorPreset]?, defaultColor: UIColor?) {
        let line = Annotation.ToolVariantID(tool: .line)
        let arrow = Annotation.ToolVariantID(tool: .line, variant: .lineArrow)
        let ink = Annotation.ToolVariantID(tool: .ink)
        let circle = Annotation.ToolVariantID(tool: .circle)
        let square = Annotation.ToolVariantID(tool: .square)
        let cloudyCircle = Annotation.ToolVariantID(tool: .circle, variant: Annotation.Variant(rawValue: "Cloudy Ellipse"))
        let dashedCircle = Annotation.ToolVariantID(tool: .circle, variant: Annotation.Variant(rawValue: "Dashed Ellipse"))
        let cloudyRectangle = Annotation.ToolVariantID(tool: .square, variant: Annotation.Variant(rawValue: "Cloudy Rectangle"))
        let dashedRectangle = Annotation.ToolVariantID(tool: .square, variant: Annotation.Variant(rawValue: "Dashed Rectangle"))
        let freeText = Annotation.ToolVariantID(tool: .freeText)
        let freeTextCallout = Annotation.ToolVariantID(tool: .freeText, variant: .freeTextCallout)

        let styleManager = SDK.shared.styleManager
        styleManager.setDefaultPresets(colorPresets, forKey: line, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: arrow, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: ink, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: circle, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: square, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: cloudyCircle, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: dashedCircle, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: cloudyRectangle, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: dashedRectangle, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: freeText, type: .colorPreset)
        styleManager.setDefaultPresets(colorPresets, forKey: freeTextCallout, type: .colorPreset)

        // Set the default color for all the tools in the annotation toolbar.
        // See https://www.nutrient.io/guides/ios/annotations/changing-default-values-for-color-and-text-size-of-annotations/ for more details.
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: line)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: arrow)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: ink)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: circle)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: square)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: cloudyCircle)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: dashedCircle)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: cloudyRectangle)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: dashedRectangle)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: freeText)
        styleManager.setLastUsedValue(defaultColor, forProperty: "color", forKey: freeTextCallout)
    }

    // MARK: Gesture recognizer action.

    @objc func addPinAnnotationGestureRecognizerDidChangeState(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended,
           let annotationToolbar = annotationToolbarController?.annotationToolbar as? ConstructionAnnotationToolbar,
           annotationToolbar.pinStampButton.isSelected,
           let documentViewController,
           let pageView = documentViewController.visiblePageView(at: gestureRecognizer.location(in: documentViewController.view)) else {
            // Return since we do not want to add a pin stamp in this case.
            return
        }

        let viewPoint = gestureRecognizer.location(in: pageView)

        // Don't create overlapping pins.
        if (pageView.annotationSelectionView?.bounds.contains(viewPoint)) != nil {
            return
        }

        // Convert the point to PDF coordinates.
        // See https://www.nutrient.io/guides/ios/faq/coordinate-spaces/ for more details.
        let pdfPoint = pageView.convert(viewPoint, to: pageView.pdfCoordinateSpace)

        // Programmatically create the pin stamp annotation and add it to the document.
        // See https://www.nutrient.io/guides/ios/annotations/programmatically-creating-annotations/#stamp-annotations for more details.
        let pinDropURL = Bundle(for: ConstructionPDFViewController.self).resourceURL!.appendingPathComponent("pin_drop_red.pdf")
        let pinStamp = PinStampAnnotation()
        pinStamp.boundingBox = CGRect(origin: pdfPoint, size: CGSize(width: 32, height: 32))
        pinStamp.appearanceStreamGenerator = FileAppearanceStreamGenerator(fileURL: pinDropURL)
        pinStamp.pageIndex = pageIndex

        // Store custom data to distinguish between a pin stamp and a regular stamp annotation.
        // See https://www.nutrient.io/guides/ios/annotations/custom-data-in-annotations/#storing-custom-data for more details.
        pinStamp.customData = ["isPinStampAnnotation": true]

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        pinStamp.contents = "Created on \(formatter.string(from: Date()))"
        document?.add(annotations: [pinStamp])

        // Present the note annotation view controller immediately.
        let noteAnnotationViewController = NoteAnnotationViewController(annotation: pinStamp)
        noteAnnotationViewController.modalPresentationStyle = .popover
        pageView.selectedAnnotations = [pinStamp]
        let annotationView = pageView.annotationView(for: pinStamp)
        present(noteAnnotationViewController, options: [.closeButton: true], animated: true, sender: annotationView)
    }

    // MARK: - PDFViewControllerDelegate

    func pdfViewController(_ pdfController: PDFViewController, shouldShow controller: UIViewController, options: [String: Any]? = nil, animated: Bool) -> Bool {
        if controller.isKind(of: StampViewController.self) {
            return false
        }
        return true
    }

    func pdfViewController(_ sender: PDFViewController, menuForAnnotations annotations: [Annotation], onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        // Keep only Comments, Delete, Inspector and Preview File actions.
        suggestedMenu
            .keep(actions: [.PSPDFKit.comments, .PSPDFKit.delete, .PSPDFKit.inspector, .PSPDFKit.previewFile])
    }

    func pdfViewController(_ sender: PDFViewController, menuForCreatingAnnotationAt point: CGPoint, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        let attachFileAction = UIAction(title: "Attach File", image: UIImage(systemName: "paperclip")) { [self] _ in
            // Store the long pressed point in PDF coordinates to be used to set
            // the bounding box of the newly created file annotation.
            longPressedPoint = pageView.pdfCoordinateSpace.convert(point, from: pageView)
            // Present the document picker.
            present(self.documentPickerController!, options: [.closeButton: true], animated: true, sender: nil)
        }
        // Keep only the Paste action and prepend our custom action.
        return suggestedMenu
            .keep(actions: [.paste])
            .prepend([attachFileAction])
    }

    func pdfViewControllerDidDismiss(_ pdfController: PDFViewController) {
        // Restore default presets to not affect other examples.
        setDefault(colorPresets: nil, defaultColor: nil)
    }

    // MARK: - PDFDocumentPickerControllerDelegate

    func documentPickerController(_ controller: PDFDocumentPickerController, didSelect document: Document, pageIndex: PageIndex, search searchString: String?) {
        let fileURL = document.fileURL
        let fileDescription = document.fileURL?.lastPathComponent

        // Create the file annotation and its embedded file
        let fileAnnotation = FileAnnotation()
        fileAnnotation.pageIndex = pageIndex
        fileAnnotation.boundingBox = CGRect(x: (self.longPressedPoint?.x)!, y: (self.longPressedPoint?.y)!, width: 32, height: 32)
        let embeddedFile = EmbeddedFile(fileURL: fileURL!, fileDescription: fileDescription)
        fileAnnotation.embeddedFile = embeddedFile

        // Add the embedded file to the document.
        self.document?.add(annotations: [fileAnnotation])
        // Dismiss the document picker.
        controller.dismiss(animated: true, completion: nil)
    }
}

/// Custom annotation toolbar class to allow the annotation toolbar customization.
/// See https://www.nutrient.io/guides/ios/customizing-the-interface/customizing-the-annotation-toolbar/ for more details.
private class ConstructionAnnotationToolbar: AnnotationToolbar {

    public var pinStampButton: ToolbarSelectableButton = ToolbarSelectableButton()

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup

        let image = Item(type: .image)
        let ink = Item(type: .ink)

        let distance = Item(type: .line, variant: .distanceMeasurement) { _, _, _ in
            SDK.imageNamed("line_distancemeasurement")!.withRenderingMode(.alwaysTemplate)
        }
        let perimeter = Item(type: .polyLine, variant: .perimeterMeasurement) { _, _, _ in
            SDK.imageNamed("polyline_perimetermeasurement")!.withRenderingMode(.alwaysTemplate)
        }
        let ellipticalArea = Item(type: .circle, variant: .ellipticalAreaMeasurement) { _, _, _ in
            SDK.imageNamed("circle_ellipticalareameasurement")!.withRenderingMode(.alwaysTemplate)
        }
        let rectangularArea = Item(type: .square, variant: .rectangularAreaMeasurement) { _, _, _ in
            SDK.imageNamed("square_rectangularareameasurement")!.withRenderingMode(.alwaysTemplate)
        }
        let polygonArea = Item(type: .polygon, variant: .polygonalAreaMeasurement) { _, _, _ in
            SDK.imageNamed("polygon_polygonalareameasurement")!.withRenderingMode(.alwaysTemplate)
        }

        let circle = Item(type: .circle)
        let cloudyCircle = Item(type: .circle, variant: Annotation.Variant(rawValue: "Cloudy Ellipse")) { _, _, _ in
            UIImage(namedInCatalog: "ellipse_cloudy")!
        }
        let dashedCircle = Item(type: .circle, variant: Annotation.Variant(rawValue: "Dashed Ellipse")) { _, _, _ in
            UIImage(namedInCatalog: "ellipse_dashed")!
        }
        let square = Item(type: .square)
        let cloudySquare = Item(type: .square, variant: Annotation.Variant(rawValue: "Cloudy Rectangle")) { _, _, _ in
            UIImage(namedInCatalog: "rectangle_cloudy")!
        }
        let dashedSquare = Item(type: .square, variant: Annotation.Variant(rawValue: "Dashed Rectangle")) { _, _, _ in
            UIImage(namedInCatalog: "rectangle_dashed")!
        }

        let line = Item(type: .line)
        let arrow = Item(type: .line, variant: .lineArrow, configurationBlock: Item.lineConfigurationBlock())

        let freeText = Item(type: .freeText)
        let freeTextCallout = Item(type: .freeText, variant: .freeTextCallout) {_, _, _ in
            return SDK.imageNamed("freetext_callout")!.withRenderingMode(.alwaysTemplate)
        }

        let note = Item(type: .note)
        let selectionTool = Item(type: .selectionTool)

        let compactGroups = [
            Group(items: [distance, perimeter, line, arrow, ink, freeText, freeTextCallout, note]),
            Group(items: [cloudySquare, cloudyCircle, dashedSquare, dashedCircle, polygonArea, ellipticalArea, rectangularArea, square, circle]),
            Group(items: [selectionTool]),
            Group(items: [image])
        ]

        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [line, arrow, ink]),
            Group(items: [distance, perimeter, polygonArea, ellipticalArea, rectangularArea]),
            Group(items: [cloudySquare, cloudyCircle, dashedSquare, dashedCircle, square, circle]),
            Group(items: [freeText, freeTextCallout, note]),
            Group(items: [selectionTool]),
            Group(items: [image])
        ]
        let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)

        configurations = [compactConfiguration, regularConfiguration]

        let fileAnnotationButton = ToolbarButton()
        fileAnnotationButton.accessibilityLabel = "Attach File"
        fileAnnotationButton.image = SDK.imageNamed("document_attachments")!.withRenderingMode(.alwaysTemplate)
        fileAnnotationButton.addTarget(self, action: #selector(fileAnnotationButtonButtonPressed(_:)), for: .touchUpInside)

        pinStampButton.accessibilityLabel = "Add Pin"
        pinStampButton.image = UIImage(namedInCatalog: "pin_drop")!.withRenderingMode(.alwaysTemplate)
        pinStampButton.addTarget(self, action: #selector(pinStampButtonButtonPressed(_:)), for: .touchUpInside)
        pinStampButton.highlightsSelection = true
        self.additionalButtons = [pinStampButton, fileAnnotationButton]
    }

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        if newState == .square || newState == .circle {
            // Update the annotation state manager's border effect property when the variant changes.
            if let variantValue = newVariant?.rawValue {
                if variantValue.hasPrefix("Cloudy") {
                    // The border effect intensity needs to be non-zero when using the cloudy border effect.
                    manager.borderEffectIntensity = 1
                    manager.borderEffect = .cloudy
                } else if variantValue.hasPrefix("Dashed") {
                    manager.borderEffectIntensity = 0
                    manager.borderEffect = .noEffect
                    manager.dashArray = [2]
                }
            } else {
                manager.borderEffectIntensity = 0
                manager.borderEffect = .noEffect
                manager.dashArray = nil
            }
        }

        // Deselect the custom pin button when changing the state.
        pinStampButton.setSelected(false, animated: true)
        super.annotationStateManager(manager, didChangeState: oldState, to: newState, variant: oldVariant, to: newVariant)
    }

    override func done(_ sender: Any?) {
        super.done(sender)

        // Deselect the custom pin button when closing the annotation toolbar.
        deselectAllTools()
    }

    public func deselectAllTools() {
        // Deselect any previously selected tool in the annotation toolbar.
        annotationStateManager.state = nil
        pinStampButton.setSelected(false, animated: false)
    }

    // MARK: Custom annotation toolbar buttons actions.

    @objc func pinStampButtonButtonPressed(_ sender: ToolbarSelectableButton) {
        // Deselect any previously selected tool in the annotation toolbar.
        annotationStateManager.state = nil
        sender.setSelected(!sender.isSelected, animated: true)
    }

    @objc func fileAnnotationButtonButtonPressed(_ sender: ToolbarButton) {
        // Deselect any previously selected tool in the annotation toolbar.
        annotationStateManager.state = nil
        pinStampButton.setSelected(false, animated: true)

        let pdfController = annotationStateManager.pdfController as! ConstructionPDFViewController
        let pageSize = pdfController.document?.pageInfoForPage(at: 0)?.size
        pdfController.longPressedPoint = CGPoint(x: pageSize!.width / 2, y: pageSize!.height / 2)
        pdfController.present(pdfController.documentPickerController!, options: [.closeButton: true], animated: true, sender: nil)
    }
}

// Hide the note icon for the pin stamp annotation.
// See https://www.nutrient.io/guides/ios/annotations/customize-annotation-rendering/#customize-or-hide-the-note-icon for more details.
private class PinStampAnnotation: StampAnnotation {
    override var shouldDrawNoteIconIfNeeded: Bool {
        let isPinStampAnnotation = customData?["isPinStampAnnotation"] as? Bool ?? false
        if isPinStampAnnotation {
            return false
        } else {
            return super.shouldDrawNoteIconIfNeeded
        }
    }

    override class var supportsSecureCoding: Bool {
        true
    }
}
