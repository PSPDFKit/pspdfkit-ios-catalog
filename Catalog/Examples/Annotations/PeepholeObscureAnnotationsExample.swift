//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class HideRevealAreaExample: Example {

    static let hideAreaKey = "hideArea"
    static let revealAreaKey = "revealArea"

    override init() {
        super.init()

        title = "Hide/Reveal Area"
        contentDescription = "Allow users to select areas to hide/reveal on a page"
        category = .annotations
        priority = 9
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .hideRevealAreaExample)

        // We use a subclassed annotation manager to use a custom annotation view for reveal areas.
        document.overrideClass(AnnotationManager.self, with: CustomAnnotationManager.self)

        // We use a subclassed square annotation to display hide and reveal area as overlay
        document.overrideClass(SquareAnnotation.self, with: CustomSquareAnnotation.self)

        let controller = HideRevealAreaPDFViewController(document: document, configuration: PDFConfiguration {
            $0.pageTransition = .scrollPerSpread
            $0.pageMode = .single
            $0.createAnnotationMenuGroups = []
            $0.isTextSelectionEnabled = false
            $0.isImageSelectionEnabled = false
            $0.allowToolbarTitleChange = false
            $0.isAutosaveEnabled = false
            $0.thumbnailBarMode = .none

            // We use a subclassed resizable view to deliver resizing/moving events to the tracking view.
            $0.overrideClass(ResizableView.self, with: CustomResizableView.self)
        })
        return controller
    }
}

private class HideRevealAreaPDFViewController: PDFViewController {

    let revealAreaButton: UIBarButtonItem
    let hideAreaButton: UIBarButtonItem

    override init(document: Document?, configuration: PDFConfiguration?) {

        revealAreaButton = UIBarButtonItem()
        hideAreaButton = UIBarButtonItem()

        super.init(document: document, configuration: configuration)

        delegate = self
        documentViewController?.delegate = self

        // Add reveal area and hide area buttons to the navigation bar and make sure their title is always updated
        revealAreaButton.target = self
        revealAreaButton.action = #selector(toggleRevealArea(_:))

        hideAreaButton.target = self
        hideAreaButton.action = #selector(toggleHideArea(_:))

        navigationItem.setRightBarButtonItems([hideAreaButton, revealAreaButton], for: .document, animated: false)

        updateButtonTitles()

        _ = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsAdded, object: nil, queue: OperationQueue.main) { _ in
            self.updateButtonTitles()
        }
        _ = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsRemoved, object: nil, queue: OperationQueue.main) { _ in
            self.updateButtonTitles()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func toggleRevealArea(_ sender: UIBarButtonItem) {
        // Check if there is an existing revealed area. If yes, delete it, if not, add a new one.
        if let revealArea = customSquare(onPageIndex: pageIndex, customDataString: HideRevealAreaExample.revealAreaKey) {
            document?.remove(annotations: [revealArea])
        } else {
            addRevealArea()
        }
    }

    @objc func toggleHideArea(_ sender: UIBarButtonItem) {
        // Check if there is an existing hidden area. If yes, delete it, if not, add a new one.
        if let hideArea = customSquare(onPageIndex: pageIndex, customDataString: HideRevealAreaExample.hideAreaKey) {
            document?.remove(annotations: [hideArea])
        } else {
            addHideArea()
        }
    }

    func customSquare(onPageIndex pageIndex: PageIndex, customDataString: String) -> Annotation? {
        // Reveal and hide areas use customData to be detectable.
        // We check here if a square annotation on a given page contains the customData value that is passed in.
        if let squares = document?.annotationsForPage(at: pageIndex, type: .square) {
            let customAnnotation = squares.first { annotation -> Bool in
                if let customDataValue = annotation.customData?[customDataString] as? Bool, customDataValue == true {
                    return true
                }
                return false
            }
            return customAnnotation
        }
        return nil
    }

    func addRevealArea() {
        // Create, and add a new reveal area to the current page, and select it.
        let pageIndex = self.pageIndex
        let revealArea = CustomSquareAnnotation()
        revealArea.isRevealArea = true
        revealArea.boundingBox = CGRect(x: 51, y: 462, width: 309, height: 168)
        revealArea.color = UIColor.clear
        // Use a color other than clear, to make tapping the transparent area select the annotation.
        revealArea.fillColor = UIColor.white.withAlphaComponent(0.0)
        revealArea.lineWidth = 0
        revealArea.pageIndex = pageIndex
        document?.add(annotations: [revealArea])
        pageViewForPage(at: pageIndex)?.selectedAnnotations = [revealArea]
    }

    func addHideArea() {
        // Create, and add a new hide area to the current page, and select it.
        let pageIndex = self.pageIndex
        let hideAreaAnnotation = CustomSquareAnnotation()
        hideAreaAnnotation.isHideArea = true
        hideAreaAnnotation.boundingBox = CGRect(x: 360, y: 80.5, width: 201, height: 552)
        hideAreaAnnotation.color = UIColor.clear
        hideAreaAnnotation.fillColor = UIColor.black
        hideAreaAnnotation.lineWidth = 0
        hideAreaAnnotation.pageIndex = pageIndex
        document?.add(annotations: [hideAreaAnnotation])
        pageViewForPage(at: pageIndex)?.selectedAnnotations = [hideAreaAnnotation]
    }

    func updateButtonTitles() {
        self.revealAreaButton.title = "Reveal Area"
        self.hideAreaButton.title = "Hide Area"

        if customSquare(onPageIndex: pageIndex, customDataString: HideRevealAreaExample.revealAreaKey) != nil {
            self.revealAreaButton.title = "Reset Reveal Area"
        }

        if customSquare(onPageIndex: pageIndex, customDataString: HideRevealAreaExample.hideAreaKey) != nil {
            self.hideAreaButton.title = "Reset Hide Area"
        }
    }
}

extension HideRevealAreaPDFViewController: PDFViewControllerDelegate {
    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, for annotations: [Annotation]?, in annotationRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        // Only allow Remove menu item
        return menuItems.filter { $0.identifier == TextMenu.annotationMenuRemove.rawValue }
    }
}

extension HideRevealAreaPDFViewController: PDFDocumentViewControllerDelegate {
    func documentViewController(_ documentViewController: PDFDocumentViewController, didChangeSpreadIndex oldSpreadIndex: Int) {
        updateButtonTitles()
    }
}

private class CustomSquareAnnotation: SquareAnnotation {

    override class var supportsSecureCoding: Bool {
        return true
    }

    override var isOverlay: Bool {
        get {
            // Always display reveal and hide areas as overlay,
            // which means that they are always rendered using their annotation view.
            if isRevealArea || isHideArea {
                return true
            }
            return super.isOverlay
        }
        set { super.isOverlay = newValue }
    }
}

private extension Annotation {
    var isRevealArea: Bool {
        // Use customData to mark an annotation as a reveal area.
        get { return customData?[HideRevealAreaExample.revealAreaKey] as? Bool ?? false }
        set { customData = [HideRevealAreaExample.revealAreaKey: newValue] }
    }

    var isHideArea: Bool {
        // Use customData to mark an annotation as a hide area.
        get { return customData?[HideRevealAreaExample.hideAreaKey] as? Bool ?? false }
        set { customData = [HideRevealAreaExample.hideAreaKey: newValue] }
    }
}

private class CustomAnnotationManager: AnnotationManager {

    override func annotationViewClass(for annotation: Annotation) -> AnyClass? {
        // Use a custom annotation view subclass for reveal areas.
        if annotation.isRevealArea {
            return RevealAreaView.self
        }
        return super.annotationViewClass(for: annotation)
    }
}

// Annotation view that displays a transparent area for the actual annotation bounding box,
// and a black area for the rest of the page.
private class RevealAreaView: AnnotationView {

    let backgroundView: UIView
    let fillLayer: CAShapeLayer

    override init(frame: CGRect) {
        // Add a background view with a shape layer to get the transparent area behavior we want.
        backgroundView = UIView()
        fillLayer = CAShapeLayer()
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        backgroundView.layer.addSublayer(fillLayer)

        isEditing = false

        super.init(frame: frame)

        self.addSubview(backgroundView)
        self.sendSubviewToBack(backgroundView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isEditing: Bool {
        didSet {
            // Make the page content shine through when we are editing (resizing or moving).
            fillLayer.opacity = isEditing ? 0.8 : 1
        }
    }

    override var pageView: PDFPageView? {
        didSet {
            if let pageView = pageView {
                updateBackgroundFrame(withBounds: pageView.bounds)
            }
        }
    }

    override func didChangePageBounds(_ bounds: CGRect) {
        updateBackgroundFrame(withBounds: bounds)
    }

    override var frame: CGRect {
        didSet {
            if let pageView = pageView {
                updateBackgroundFrame(withBounds: pageView.bounds)

                // Whenever the annotation view's frame change, we want to update the path for the shape layer.

                // We use a bezier path consiting of the page view bounds and the current annotation view's frame
                // while using the evenOdd fill rule, to get the expected behavior with the page content being covered in black
                // while the actual annotation bounding box is still transparent, with the page content being visible.
                let pagePath = UIBezierPath(rect: pageView.bounds)
                let annotationPath = UIBezierPath(rect: frame)

                pagePath.append(annotationPath)
                pagePath.usesEvenOddFillRule = true

                fillLayer.path = pagePath.cgPath
            }
        }
    }

    func updateBackgroundFrame(withBounds bounds: CGRect) {
        // Make sure the background view is always positioned correctly, covering the whole page view.
        var backgroundFrame = bounds
        backgroundFrame.origin = CGPoint(x: -self.frame.origin.x, y: -self.frame.origin.y)
        self.backgroundView.frame = backgroundFrame
    }
}

private class CustomResizableView: ResizableView, ResizableViewDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Let the annotation view know when the reveal area is resized or moved.

    func resizableViewDidBeginEditing(_ resizableView: ResizableView) {
        guard let revealAreaView = self.trackedViews?.first(where: { $0 is RevealAreaView }) as? RevealAreaView else { return }
        revealAreaView.isEditing = true
    }

    func resizableViewDidEndEditing(_ resizableView: ResizableView, didChangeFrame: Bool) {
        guard let revealAreaView = self.trackedViews?.first(where: { $0 is RevealAreaView }) as? RevealAreaView else { return }
        revealAreaView.isEditing = false
    }
}
