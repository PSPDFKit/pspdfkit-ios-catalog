//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// This example uses the following PSPDFKit features:
/// - Viewer
/// - Annotations
/// - Indexed Search
/// - Replies
///
/// See https://pspdfkit.com/pdf-sdk/ios/ for the complete list of features for PSPDFKit for iOS.

class ConstructionExample: IndustryExample {

    override init() {
        super.init()

        title = "Construction"
        contentDescription = "Shows how to configure PSPDFKit to display a building floor plan."
        category = .industryExamples
        priority = 5
        extendedDescription = """
        This example shows how to customize the annotation toolbar for the construction industry by adding the following custom tools:

        1. The drop pin tool — this lets the user create tasks on specific areas of the building floor plan.
        2. The file attachment tool — this lets the user attach documents to the floor plan document.
        """
        url = URL(string: "https://pspdfkit.com/blog/2021/industry-solution-construction-ios/")!
        if #available(iOS 14.0, *) {
            image = UIImage(systemName: "building.2.crop.circle")
        }
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

    /// Used for showing the more info alert.
    private var moreInfo: MoreInfoCoordinator!

    init(with example: IndustryExample) {
        let document = AssetLoader.writableDocument(for: .constructionPlan, overrideIfExists: false)
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

            // Customize the sharing experience.
            $0.sharingConfigurations = [emailConfiguration]

            // Configure the properties for annotation inspector.
            var annotationProperties = $0.propertiesForAnnotations
            annotationProperties[.ink] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.line] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.square] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.circle] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.freeText] = [[.fontSize, .fontName, .textAlignment, .color, .fillColor, .calloutAction]] as [[AnnotationStyle.Key]]
            $0.propertiesForAnnotations = annotationProperties

            // Miscellaneous configuration options.
            $0.backgroundColor = UIColor.psc_secondarySystemBackground
            $0.thumbnailBarMode = .none
            $0.spreadFitting = .fit
            $0.isPageLabelEnabled = false
            $0.documentLabelEnabled = .NO
        }

        super.init(document: document, configuration: configuration)

        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        delegate = self

        documentPickerController = PDFDocumentPickerController(directory: "/Bundle/Samples", includeSubdirectories: true, library: SDK.shared.library)
        documentPickerController?.delegate = self

        // Configure custom default color presets.
        // See https://pspdfkit.com/guides/ios/annotations/customizing-presets/ for more details.
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

        let annotationToolbarProxy = ConstructionAnnotationToolbar.appearance()
        let barColor = UIColor(white: 0.2, alpha: 0.98)

        let appearance = UIToolbarAppearance()
        appearance.backgroundColor = barColor

        annotationToolbarProxy.standardAppearance = appearance
        annotationToolbarProxy.compactAppearance = appearance
        annotationToolbarProxy.tintColor = UIColor(white: 0.95, alpha: 0.98)

        // Customize the toolbar.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        let annotationListButtonItem = UIBarButtonItem(image: SDK.imageNamed("document_annotations")!, style: outlineButtonItem.style, target: outlineButtonItem.target, action: outlineButtonItem.action)
        navigationItem.rightBarButtonItems = [annotationButtonItem, activityButtonItem, annotationListButtonItem]
        navigationItem.leftBarButtonItems = [moreInfo.barButton, toggleAnnotationVisibilityBarButtonItem]
        navigationItem.leftItemsSupplementBackButton = true

        // Only show the annotations list in the document info.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-available-document-information/ for more details.
        documentInfoCoordinator.availableControllerOptions = [.annotations]

        // Only support the right position for the annotation toolbar.
        let annotationToolbar = annotationToolbarController?.annotationToolbar
        annotationToolbar?.supportedToolbarPositions = .right
        annotationToolbar?.toolbarPosition = .right
        annotationToolbar?.isDragEnabled = false

        // Setup a tap gesture recognizer that adds a pin annotation to the page if the pin annotation tool is selected.
        let addPinAnnotationGestureRecognizer = UITapGestureRecognizer()
        addPinAnnotationGestureRecognizer.addTarget(self, action: #selector(addPinAnnotationGestureRecognizerDidChangeState))

        // Make it work simultaneously with all built-in interaction components.
        interactions.allInteractions.allowSimultaneousRecognition(with: addPinAnnotationGestureRecognizer)
        // Add the gesture recognizer to the document view controller's view.
        documentViewController?.view.addGestureRecognizer(addPinAnnotationGestureRecognizer)

        // Disable text interaction.
        interactions.allTextInteractions.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
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
        let rect = super.flexibleToolbarContainerContentRect(container, for: position)
        if position == .right && UIDevice.current.userInterfaceIdiom == .pad {
            let offset = (view.frame.size.height - 710) / 2
            return rect.inset(by: UIEdgeInsets(top: -offset, left: 0, bottom: offset, right: 0))
        } else {
            return rect
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
        // See https://pspdfkit.com/guides/ios/annotations/changing-default-values-for-color-and-text-size-of-annotations/ for more details.
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
           let documentViewController = documentViewController,
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
        // See https://pspdfkit.com/guides/ios/faq/coordinate-spaces/ for more details.
        let pdfPoint = pageView.convert(viewPoint, to: pageView.pdfCoordinateSpace)

        // Programmatically create the pin stamp annotation and add it to the document.
        // See https://pspdfkit.com/guides/ios/annotations/programmatically-creating-annotations/#stamp-annotations for more details.
        let pinDropURL = Bundle(for: ConstructionPDFViewController.self).resourceURL!.appendingPathComponent("pin_drop_red.pdf")
        let pinStamp = PinStampAnnotation()
        pinStamp.boundingBox = CGRect(origin: pdfPoint, size: CGSize(width: 32, height: 32))
        pinStamp.appearanceStreamGenerator = FileAppearanceStreamGenerator(fileURL: pinDropURL)
        pinStamp.pageIndex = pageIndex

        // Store custom data to distinguish between a pin stamp and a regular stamp annotation.
        // See https://pspdfkit.com/guides/ios/annotations/custom-data-in-annotations/#storing-custom-data for more details.
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

    /// Customize the long press menus.
    /// See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-menus/ for more details.
    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, for annotations: [Annotation]?, in annotationRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        // Only allow the remove, paste, preview file, and note menus.
        var allMenuItems: [MenuItem] = menuItems.filter {
            $0.identifier == TextMenu.annotationMenuRemove.rawValue ||
            $0.identifier == TextMenu.annotationMenuPaste.rawValue ||
            $0.identifier == TextMenu.annotationMenuPreviewFile.rawValue ||
            $0.identifier == TextMenu.annotationMenuNote.rawValue
        }

        // Long pressed on the page view.
        if annotations == nil {
            let attachFileMenuItem = MenuItem(title: "Attach File") {
                // Store the long pressed point in PDF coordinates to be used to set the bounding box of the newly created file annotation.
                self.longPressedPoint = pageView.convert(rect, to: pageView.pdfCoordinateSpace).origin
                // Present the document picker.
                self.present(self.documentPickerController!, options: [.closeButton: true], animated: true, sender: nil)
            }
            // Add the new menu item to be the first (leftmost) item.
            allMenuItems.insert(attachFileMenuItem, at: 0)
        }

        return allMenuItems
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
/// See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-annotation-toolbar/ for more details.
private class ConstructionAnnotationToolbar: AnnotationToolbar {

    public var pinStampButton: ToolbarSelectableButton = ToolbarSelectableButton()

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup

        let image = Item(type: .image)
        let ink = Item(type: .ink)

        let circle = Item(type: .circle)
        let cloudyCircle = Item(type: .circle, variant: Annotation.Variant(rawValue: "Cloudy Ellipse")) {_, _, _ in
            UIImage(namedInCatalog: "ellipse_cloudy")!.withRenderingMode(.alwaysTemplate)
        }
        let dashedCircle = Item(type: .circle, variant: Annotation.Variant(rawValue: "Dashed Ellipse")) {_, _, _ in
            UIImage(namedInCatalog: "ellipse_dashed")!.withRenderingMode(.alwaysTemplate)
        }
        let square = Item(type: .square)
        let cloudySquare = Item(type: .square, variant: Annotation.Variant(rawValue: "Cloudy Rectangle")) {_, _, _ in
            UIImage(namedInCatalog: "rectangle_cloudy")!.withRenderingMode(.alwaysTemplate)
        }
        let dashedSquare = Item(type: .square, variant: Annotation.Variant(rawValue: "Dashed Rectangle")) {_, _, _ in
            UIImage(namedInCatalog: "rectangle_dashed")!.withRenderingMode(.alwaysTemplate)
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
            Group(items: [line, arrow, ink, freeText, freeTextCallout, note]),
            Group(items: [cloudySquare, cloudyCircle, dashedSquare, dashedCircle, square, circle]),
            Group(items: [selectionTool]),
            Group(items: [image])
        ]

        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [line, arrow, ink]),
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
// See https://pspdfkit.com/guides/ios/annotations/customize-annotation-rendering/#customize-or-hide-the-note-icon for more details.
private class PinStampAnnotation: StampAnnotation {
    override var shouldDrawNoteIconIfNeeded: Bool {
        let isPinStampAnnotation = customData?["isPinStampAnnotation"] as? Bool ?? false
        if isPinStampAnnotation {
            return false
        } else {
            return super.shouldDrawNoteIconIfNeeded
        }
    }
}
