//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import MapKit

/// This example uses the following PSPDFKit features:
/// - Viewer
/// - Annotations
///
/// See https://pspdfkit.com/pdf-sdk/ios/ for the complete list of features for PSPDFKit for iOS.

class AviationExample: IndustryExample {

    override init() {
        super.init()

        title = "Aviation"
        contentDescription = "Shows how to configure PSPDFKit to display a flight plan for pilots and a passenger list for the cabin crew."
        category = .industryExamples
        priority = 6
        extendedDescription = """
        This example shows how to configure the user interface for dark appearance even when the device is using the light appearance.

        This example also shows how to render documents for night mode, which is useful for pilots flying at night.
        """
        url = URL(string: "https://pspdfkit.com/blog/2021/industry-solution-aviation-ios/")!
        if #available(iOS 14.0, *) {
            image = UIImage(systemName: "airplane.circle")
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let flightManualContainerController = FlightManualContainerController(with: self)
        let passengerListContainerController = PassengerListContainerController(with: self)
        let flightManualNavigationController = UINavigationController(rootViewController: flightManualContainerController)
        let passengerListNavigationController = UINavigationController(rootViewController: passengerListContainerController)
        let navigationControllers = [flightManualNavigationController, passengerListNavigationController]

        // Setup the tab bar controller.
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = navigationControllers
        tabBarController.navigationItem.largeTitleDisplayMode = .never
        tabBarController.modalPresentationStyle = .fullScreen

        // Force Dark Mode.
        tabBarController.overrideUserInterfaceStyle = .dark

        // Make the toolbar more opaque over the busy map background.
        // This setting will be automatically matched by the PSPDFKit annotation toolbar.
        let appearance = UINavigationBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThickMaterialDark)
        navigationControllers.forEach {
            $0.navigationBar.standardAppearance = appearance
            $0.navigationBar.compactAppearance = appearance
        }

        delegate.currentViewController?.present(tabBarController, animated: true)
        return nil
    }
}

/// Custom container view controller subclass for the flight manual.
private class FlightManualContainerController: UIViewController, MKMapViewDelegate {

    init(with example: IndustryExample) {
        super.init(nibName: nil, bundle: nil)
        let flightManualPDFController = FlightManualPDFViewController(with: example)

        // Embed a map view and the PDFViewController in a container view controller.
        let flightManualContainerController = UIViewController()
        title = "Flight Manual"
        flightManualPDFController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(flightManualPDFController)
        view.addSubview(mapView)
        view.addSubview(flightManualPDFController.view)
        flightManualPDFController.didMove(toParent: flightManualContainerController)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: mapView.topAnchor),
            view.bottomAnchor.constraint(equalTo: flightManualPDFController.view.bottomAnchor),
            flightManualPDFController.view.topAnchor.constraint(equalTo: mapView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: flightManualPDFController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: flightManualPDFController.view.trailingAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalToConstant: view.frame.height / 3),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var mapView: MKMapView = {
        // Embed a map view and the PDFViewController in a container view controller.
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.mapType = .hybridFlyover
        mapView.showsTraffic = false
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.translatesAutoresizingMaskIntoConstraints = false

        // Set the region of the map view.
        let locationCoordinate = CLLocationCoordinate2DMake(48.12, 16.5685)
        let region = MKCoordinateRegion(center: locationCoordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
        mapView.setRegion(region, animated: false)

        // Add a point annotation to the map.
        let mapAnnotation = MKPointAnnotation()
        mapAnnotation.title = "Vienna International Airport"
        mapAnnotation.coordinate = locationCoordinate
        mapView.addAnnotation(mapAnnotation)
        return mapView
    }()

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        let identifier = "MapAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.image = UIImage(namedInCatalog: "airplane")
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }
}

/// Custom PDF view controller subclass for the flight manual.
private class FlightManualPDFViewController: AviationPDFViewController {

    init(with example: IndustryExample) {
        let document = AssetLoader.writableDocument(for: .flightManual, overrideIfExists: false)
        document.title = "Flight Manual"

        // Customize document sharing.
        // See https://pspdfkit.com/guides/ios/miscellaneous/document-sharing/ for more details.
        let emailConfiguration = DocumentSharingConfiguration.defaultConfiguration(forDestination: .activity).configurationUpdated {
            $0.destination = .email
            $0.fileFormatOptions = .PDF
            $0.annotationOptions = [.embed, .remove]
            $0.pageSelectionOptions = [.all]
        }

        let printConfiguration = DocumentSharingConfiguration.defaultConfiguration(forDestination: .activity).configurationUpdated {
            $0.destination = .print
            $0.fileFormatOptions = .PDF
            $0.annotationOptions = [.flattenForPrint, .remove]
            $0.pageSelectionOptions = [.all]
        }

        let configuration = PDFConfiguration {
            // Customize the annotation toolbar.
            $0.overrideClass(AnnotationToolbar.self, with: AviationAnnotationToolbar.self)

            // Customize the sharing experience.
            $0.sharingConfigurations = [emailConfiguration, printConfiguration]

            // Document view options.
            $0.pageTransition = .scrollPerSpread
            $0.scrollDirection = .horizontal
            $0.pageMode = .single
            $0.spreadFitting = .fit

            // Only allow default and night appearance modes. This will exclude sepia.
            $0.allowedAppearanceModes = [.night]

            // Configure the properties for annotation inspector.
            var annotationProperties = $0.propertiesForAnnotations
            annotationProperties[.ink] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.square] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.circle] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.line] = [[.color, .alpha, .lineWidth]] as [[AnnotationStyle.Key]]
            annotationProperties[.freeText] = [[.fontSize, .fontName, .textAlignment, .color, .fillColor, .calloutAction]] as [[AnnotationStyle.Key]]

            $0.propertiesForAnnotations = annotationProperties

            // Miscellaneous configuration options.
            $0.thumbnailBarMode = .scrubberBar
            $0.searchMode = .modal
            $0.useParentNavigationBar = true
            $0.userInterfaceViewMode = .always

            // When `.top` is a supported toolbar position, the document label must be disabled.
            $0.documentLabelEnabled = .NO
        }

        super.init(document: document, configuration: configuration)

        // Customize the toolbar.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        navigationItem.rightBarButtonItems = [activityButtonItem, outlineButtonItem]
        navigationItem.leftBarButtonItems = [closeButtonItem, moreInfo.barButton, brightnessButtonItem, annotationButtonItem]

        // Force the night appearance mode.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/appearance-mode-manager/ for more details.
        appearanceModeManager.appearanceMode = .night

        // Do not reset the appearance mode when the view disappears.
        shouldResetAppearanceModeWhenViewDisappears = false

        // Only support the top in the main toolbar position for the annotation toolbar.
        annotationToolbarController?.annotationToolbar.supportedToolbarPositions = .inTopBar
        annotationToolbarController?.annotationToolbar.toolbarPosition = .inTopBar

        // Only show the outlines and bookmarks in the document info.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-available-document-information/ for more details.
        documentInfoCoordinator.availableControllerOptions = [.outline, .bookmarks]

        // Do not show the filter options segmented control when viewing the thumbnails.
        thumbnailController.filterOptions = nil

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Custom container view controller subclass for the passenger list.
private class PassengerListContainerController: UIViewController {
    init(with example: IndustryExample) {
        super.init(nibName: nil, bundle: nil)
        // Create the passenger list PDF view controller.
        let passengerListPDFController = PassengerListPDFViewController(with: example)

        // Embed the PDFViewController in a container view controller.
        title = "Passenger List"
        addChild(passengerListPDFController)
        view.addSubview(passengerListPDFController.view)
        passengerListPDFController.didMove(toParent: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Custom PDF view controller subclass for the passenger list.
private class PassengerListPDFViewController: AviationPDFViewController {

    init(with example: IndustryExample) {
        let document = AssetLoader.writableDocument(for: .passengerList, overrideIfExists: false)
        document.title = "Passenger List"

        let configuration = PDFConfiguration {
            // Customize the annotation toolbar.
            $0.overrideClass(AnnotationToolbar.self, with: AviationAnnotationToolbar.self)

            // Document view options.
            $0.pageTransition = .scrollContinuous
            $0.scrollDirection = .vertical
            $0.pageMode = .single
            $0.spreadFitting = .fill

            // Only allow default and night appearance modes. This will exclude sepia.
            $0.allowedAppearanceModes = [.night]

            // Miscellaneous configuration options.
            $0.thumbnailBarMode = .scrubberBar
            $0.searchMode = .inline
            $0.useParentNavigationBar = true
            $0.userInterfaceViewMode = .always

            // When `.top` is a supported toolbar position, the document label must be disabled.
            $0.documentLabelEnabled = .NO
        }

        super.init(document: document, configuration: configuration)

        // Do not reset the appearance mode when the view disappears.
        shouldResetAppearanceModeWhenViewDisappears = false

        // Customize the toolbar.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        navigationItem.rightBarButtonItems = [activityButtonItem, annotationButtonItem, searchButtonItem]
        navigationItem.leftBarButtonItems = [closeButtonItem, moreInfo.barButton, brightnessButtonItem, toggleAnnotationVisibilityBarButtonItem]

        // Only support the top in the main toolbar position for the annotation toolbar.
        annotationToolbarController?.annotationToolbar.supportedToolbarPositions = .inTopBar
        annotationToolbarController?.annotationToolbar.toolbarPosition = .inTopBar

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Custom PDF view controller class.
private class AviationPDFViewController: PDFViewController, PDFViewControllerDelegate {

    /// Used for showing the more info alert.
    var moreInfo: MoreInfoCoordinator!

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        delegate = self

        // Customize the default stamps.
        // See https://pspdfkit.com/guides/ios/annotations/stamp-annotations-configuration/ for more details.
        var defaultStamps = [StampAnnotation]()
        let approvedStamp = StampAnnotation(title: "Approved")
        approvedStamp.boundingBox = CGRect(x: 0, y: 0, width: 200, height: 70)
        approvedStamp.color = UIColor.green
        defaultStamps.append(approvedStamp)
        let rejectedStamp = StampAnnotation(title: "Rejected")
        rejectedStamp.boundingBox = CGRect(x: 0, y: 0, width: 200, height: 70)
        rejectedStamp.color = UIColor.red
        defaultStamps.append(rejectedStamp)

        StampViewController.defaultStampAnnotations = defaultStamps

        // Disable text interaction.
        interactions.allTextInteractions.isEnabled = false
    }

    // Cleanup to avoid affecting other examples.
    deinit {
        // Reset the default stamps so other examples will use the default stamps.
        StampViewController.defaultStampAnnotations = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

    lazy var toggleAnnotationVisibilityBarButtonItem: UIBarButtonItem = {
        let toggleAnnotationVisibility = UIBarButtonItem(image: UIImage(namedInCatalog: "hide"), style: .plain, target: self, action: #selector(didTapToggleAnnotationVisibilityBarButtonItem))
        toggleAnnotationVisibility.title = "hide"
        return toggleAnnotationVisibility
    }()

    // MARK: Private

    private lazy var mapView: UIView? = {
        return parent?.view.subviews.first(where: { $0.isKind(of: MKMapView.self) })
    }()

    @objc private func didTapToggleAnnotationVisibilityBarButtonItem(_ sender: UIBarButtonItem) {
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

    // MARK: FlexibleToolbarContainerDelegate

    override func flexibleToolbarContainerWillShow(_ container: FlexibleToolbarContainer) {
        // Disable user interaction and dim the map view when annotation toolbar becomes visible.
        if let mapView = mapView {
            mapView.isUserInteractionEnabled = false
            mapView.mask = UIView(frame: mapView.frame)
            mapView.mask?.backgroundColor = .black
            mapView.mask?.alpha = 0.5
        }

        // If the annotations visibility is disabled, we enable the visibility when annotation toolbar becomes visible.
        if toggleAnnotationVisibilityBarButtonItem.title == "show" {
            didTapToggleAnnotationVisibilityBarButtonItem(toggleAnnotationVisibilityBarButtonItem)
        }
    }

    override func flexibleToolbarContainerWillHide(_ container: FlexibleToolbarContainer) {
        // Restore the map view's state when annotation toolbar will hide.
        if let mapView = mapView {
            mapView.isUserInteractionEnabled = true
            mapView.mask = nil
        }
    }

    // MARK: - PDFViewControllerDelegate

    func pdfViewController(_ pdfController: PDFViewController, shouldShow controller: UIViewController, options: [String: Any]? = nil, animated: Bool) -> Bool {
        // Customize the stamp view controller.
        let stampController = PSPDFChildViewControllerForClass(controller, StampViewController.self) as? StampViewController
        stampController?.customStampEnabled = false
        stampController?.dateStampsEnabled = false

        // Force Dark Mode for presented controllers.
        let presentationRoot = controller.navigationController ?? controller
        presentationRoot.overrideUserInterfaceStyle = .dark

        return true
    }

    // Customize the long press menus.
    // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-menus/ for more details.
    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, for annotations: [Annotation]?, in annotationRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        // Remove the signature, ink highlighter, image, stamp, sound, and eraser menus.
        let disabledMenuItems = [
            Annotation.ToolVariantID(tool: .signature).rawValue,
            Annotation.ToolVariantID(tool: .ink, variant: .inkHighlighter).rawValue,
            Annotation.ToolVariantID(tool: .image).rawValue,
            Annotation.ToolVariantID(tool: .stamp).rawValue,
            Annotation.ToolVariantID(tool: .sound).rawValue,
            Annotation.ToolVariantID(tool: .eraser).rawValue
        ]
        var allowedMenuItems: [MenuItem] = menuItems.filter {
            if let identifier = $0.identifier {
                return disabledMenuItems.contains(identifier) == false
            } else {
                return false
            }
        }

        // Add a custom menu to invert the appearance mode.
        let invertColorsMenuItem = MenuItem(title: "Invert Colors") {
            if self.appearanceModeManager.appearanceMode == .night {
                self.appearanceModeManager.appearanceMode = []
            } else {
                self.appearanceModeManager.appearanceMode = .night
            }
        }
        // Append the new menu item to be the last (rightmost) item.
        allowedMenuItems.append(invertColorsMenuItem)
        return allowedMenuItems
    }
}

/// Custom annotation toolbar class to allow the annotation toolbar customization.
/// See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-annotation-toolbar/ for more details.
private class AviationAnnotationToolbar: AnnotationToolbar {

    private var observer: Any?
    private var clearAnnotationsButton: ToolbarButton = ToolbarButton()

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        // The annotation toolbar will unregister all notifications on dealloc.
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationChanged, object: nil, queue: OperationQueue.main) { notification in self.annotationChangedNotification(notification)
        }
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsAdded, object: nil, queue: OperationQueue.main) { notification in self.annotationChangedNotification(notification)
        }
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsRemoved, object: nil, queue: OperationQueue.main) { notification in self.annotationChangedNotification(notification)
        }
        observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.PSPDFDocumentViewControllerWillBeginDisplayingSpreadView, object: nil, queue: OperationQueue.main) { notification in self.willShowSpreadViewNotification(notification)
        }

        // Customize the annotation toolbar buttons.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-annotation-toolbar/#annotation-buttons for more details.
        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
        let ink = Item(type: .ink)
        let square = Item(type: .square)
        let circle = Item(type: .circle)
        let line = Item(type: .line)
        let freeText = Item(type: .freeText)
        let note = Item(type: .note)
        let stamp = Item(type: .stamp)
        let selectionTool = Item(type: .selectionTool)

        let compactGroups = [
            Group(items: [ink]),
            Group(items: [square, circle, line]),
            Group(items: [freeText, note]),
            Group(items: [stamp]),
            Group(items: [selectionTool])
        ]

        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [ink]),
            Group(items: [square]),
            Group(items: [circle]),
            Group(items: [line]),
            Group(items: [freeText]),
            Group(items: [note]),
            Group(items: [stamp]),
            Group(items: [selectionTool])
        ]

        let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)

        configurations = [compactConfiguration, regularConfiguration]

        let clearImage = SDK.imageNamed("trash")?.withRenderingMode(.alwaysTemplate)
        clearAnnotationsButton.accessibilityLabel = "Clear"
        clearAnnotationsButton.image = clearImage
        clearAnnotationsButton.addTarget(self, action: #selector(clearButtonPressed(_:)), for: .touchUpInside)

        self.additionalButtons = [clearAnnotationsButton]
        updateClearAnnotationButton()
    }

    // MARK: Clear Button Action

    @objc func clearButtonPressed(_ sender: ToolbarButton) {
        let pdfController = annotationStateManager.pdfController
        let document = pdfController?.document
        let allTypesButLinkAndForms = Annotation.Kind.all.subtracting([.link, .widget])
        guard let annotations = document?.allAnnotations(of: allTypesButLinkAndForms).flatMap({ $0.value }) else {
            return
        }

        document?.remove(annotations: annotations, options: nil)
        SDK.shared.cache.remove(for: document)
        pdfController?.reloadData()
    }

    // MARK: Notifications

    func annotationChangedNotification(_ notification: Notification) {
        // Re-evaluate toolbar button
        if self.window != nil {
            updateClearAnnotationButton()
        }
    }

    func willShowSpreadViewNotification(_ notification: Notification) {
        updateClearAnnotationButton()
    }

    // MARK: PDFAnnotationStateManagerDelegate

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeUndoState undoEnabled: Bool, redoState redoEnabled: Bool) {
        super.annotationStateManager(manager, didChangeUndoState: undoEnabled, redoState: redoEnabled)
        updateClearAnnotationButton()
    }

    // MARK: Private

    private func updateClearAnnotationButton() {
        let pdfController = annotationStateManager.pdfController
        let document = pdfController?.document
        let allTypesButLinkAndForms = Annotation.Kind.all.subtracting([.link, .widget])
        guard let annotations = document?.allAnnotations(of: allTypesButLinkAndForms) else { return }
        // Enable the button only if there are annotations found to clear.
        clearAnnotationsButton.isEnabled = annotations.isEmpty == false
    }
}
