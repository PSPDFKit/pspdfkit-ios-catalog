//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class OverlayViewsExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()
        title = "Adding Overlay Views"
        contentDescription = "Shows how to add custom overlay views on top of pages."
        category = .controllerCustomization
        priority = 40
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        PDFViewController(document: AssetLoader.document(for: .JKHF), delegate: self) { builder in
            builder.maximumZoomScale = 20
        }
    }

    func pdfViewController(_ pdfController: PDFViewController, didConfigurePageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        // This is the size pf page and overlay in PDF coordinate space.
        // See: https://pspdfkit.com/guides/ios/faq/coordinate-spaces
        guard let pageSize = pageView.pageInfo?.size else { return }
        let overlaySize = CGSize(width: 30, height: 30)
        // Add 4 custom views at the 4 corners of the first page. PSPDFKit will
        // reuse the page view but in doing so it will clear all foreign views,
        // so you don't have to remove them youself.
        guard pageView.pageIndex == 0 else { return }
        // Top-left is actually "bottom-left" in PDF coordinates.
        let topLeftBoundingBox = CGRect(x: 0, y: pageSize.height - overlaySize.height, width: overlaySize.width, height: overlaySize.height)
        let topLeftView = OverlayView(on: pageView, boundingBox: topLeftBoundingBox, color: .yellow)
        pageView.annotationContainerView.addSubview(topLeftView)
        // Top-right is actually "bottom-right" in PDF coordinates.
        let topRightBoundingBox = CGRect(x: pageSize.width - overlaySize.width, y: pageSize.height - overlaySize.height, width: overlaySize.width, height: overlaySize.height)
        let topRightView = OverlayView(on: pageView, boundingBox: topRightBoundingBox, color: .red)
        pageView.annotationContainerView.addSubview(topRightView)
        // Bottom-right is actually "top-right" in PDF coordinates.
        let bottomRightBoundingBox = CGRect(x: pageSize.width - overlaySize.width, y: 0, width: overlaySize.width, height: overlaySize.height)
        let bottomRightView = OverlayView(on: pageView, boundingBox: bottomRightBoundingBox, color: .green)
        pageView.annotationContainerView.addSubview(bottomRightView)
        // Bottom-left is actually "top-left" in PDF coordinates.
        let bottomLeftBoundingBox = CGRect(origin: .zero, size: overlaySize)
        let bottomLeftView = OverlayView(on: pageView, boundingBox: bottomLeftBoundingBox, color: .blue)
        pageView.annotationContainerView.addSubview(bottomLeftView)
    }

}

private class OverlayView: UIView, AnnotationPresenting {

    init(on pageView: PDFPageView, boundingBox: CGRect, color backgroundColor: UIColor) {
        self.pageView = pageView
        self.boundingBox = boundingBox
        super.init(frame: .zero)
        self.backgroundColor = backgroundColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var pageView: PDFPageView?
    private let boundingBox: CGRect

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        // Update the frame when this view is first added to the hierarchy.
        updateFrameBasedOnBoundingBox()
    }

    func didChangePageBounds(_ bounds: CGRect) {
        // Update the frame once the page rotates.
        updateFrameBasedOnBoundingBox()
    }

    private func updateFrameBasedOnBoundingBox() {
        guard let pageView = pageView, let superview = superview else { return }
        frame = superview.convert(boundingBox, from: pageView.pdfCoordinateSpace)
    }

}
