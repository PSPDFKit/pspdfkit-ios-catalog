//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class FloatingStampsExample: Example {

    override init() {
        super.init()

        title = "Floating Stamps"
        contentDescription = "Custom stamp annotations that have a fixed size and do not zoom with the page"
        category = .annotations
        priority = 2000
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .about)

        let controller = PDFViewController(document: document) {
            $0.overrideClass(StampAnnotation.self, with: FloatingStamp.self)
        }
        controller.delegate = self

        return controller
    }
}

extension FloatingStampsExample: PDFViewControllerDelegate {
    internal func pdfViewController(_ pdfController: PDFViewController, annotationView: (UIView & AnnotationPresenting)?, for annotation: Annotation, on pageView: PDFPageView) -> (UIView & AnnotationPresenting)? {
        if annotation is StampAnnotation {
            let frame = annotation.boundingBox(forPageRect: pageView.bounds)
            let customView = FloatingStampView(frame: frame)
            return customView
        }
        return annotationView
    }
}

private class FloatingStamp: StampAnnotation {

    override var fixedSize: CGSize {
        var aspectRatio: CGFloat = 1
        if boundingBox.size != .zero {
            aspectRatio = boundingBox.height / boundingBox.width
        }
        return CGSize(width: 100, height: 100 * aspectRatio)
    }

    override var isOverlay: Bool {
        get {
            return true
        }
        // swiftlint:disable:next unused_setter_value
        set {}
    }

    override var isResizable: Bool {
        return false
    }
}

private class FloatingStampView: AnnotationView {

    private lazy var annotationImageView: UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(annotationImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var annotation: Annotation? {
        didSet {
            updateImage()
        }
    }

    override var zoomScale: CGFloat {
        didSet {
            let scale = fmax(1, zoomScale)
            annotationImageView.transform = CGAffineTransform(scaleX: 1 / scale, y: 1 / scale)
        }
    }

    func renderAnnotationImage() -> UIImage? {
        guard let annotation = annotation else { return nil }
        return annotation.image(size: annotation.fixedSize, options: nil)
    }

    override func annotationChangedNotification(_ notification: Notification) {
        super.annotationChangedNotification(notification)
        updateImage()
    }

    func updateImage() {
        annotationImageView.image = renderAnnotationImage()
        annotationImageView.alpha = annotation?.alpha ?? 0
    }
}
