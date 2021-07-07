//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

/// Swift code from https://pspdfkit.com/guides/ios/customizing-pdf-pages/adding-auxiliary-or-decorative-views/
///
/// For an in-depth explanation of the classes and structs, please read this article, as well as its companion guide
/// “Customizing Interactions with an Annotation Type”.
class SpreadMeasurementsExample: Example {
    override init() {
        super.init()
        title = "Measurements on Pages/Spreads"
        contentDescription = "Shows how to add auxilary views to spreads/pages"
        category = .viewCustomization
    }

    private var manager: MeasuringPDFControllerManager?
    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        manager = .init()
        manager?.document = AssetLoader.document(for: .quickStart)

        return manager?.documentViewController
    }
}

// MARK: - Measurement and Datasource:

protocol SpreadMeasurement {
    var pageRange: NSRange { get }
    var path: CGPath { get }
    var value: Measurement<Dimension> { get }
}

protocol DocumentMeasurementDatasource: AnyObject {
    func measurements(at pageIndex: Int) -> [SpreadMeasurement]
}

// MARK: - View and Extension:

private extension SpreadMeasurement {
    var isArea: Bool {
        value.unit is UnitArea
    }
}

private class SpreadMeasurementView: UIView, AnnotationPresenting {
    var pdfScale: CGFloat {
        didSet {
            if oldValue != pdfScale, let measurement = measurement {
                // The transform for PDF to page view coordinates just changed, so we have to adapt
                updateFrameAndLayer(measurement: measurement, scale: pdfScale)
            }
        }
    }

    var zoomScale: CGFloat {
        didSet {
            // make sure the label is always crisp
            let viewScale = window?.screen.scale ?? 1
            dimensionLabel.contentScaleFactor = zoomScale * viewScale
        }
    }

    func prepareForReuse() {
        measurement = nil
    }

    var measurement: SpreadMeasurement? {
        didSet {
            guard let measurement = measurement else {
                dimensionLabel.isHidden = true
                shapeLayer.path = nil

                return
            }

            dimensionLabel.isHidden = false
            dimensionLabel.text = formatter.string(from: measurement.value)
            updateFrameAndLayer(measurement: measurement, scale: pdfScale)
            if measurement.isArea {
                shapeLayer.fillColor = UIColor(white: 0.2, alpha: 0.4).cgColor
                shapeLayer.lineDashPattern = nil
            } else {
                shapeLayer.fillColor = nil
                shapeLayer.lineDashPattern = [5, 3, 2, 3]
            }
        }
    }

    private func updateFrameAndLayer(measurement: SpreadMeasurement, scale: CGFloat) {
        guard scale > 0 else {
            return
        }

        let path = measurement.path
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        let boundingBox = path.boundingBox.applying(transform)
        frame = boundingBox

        // The layer is in coordinates of the bounds so we need to account for the offset, too
        transform.tx = -boundingBox.origin.x
        transform.ty = -boundingBox.origin.y
        shapeLayer.path = path.copy(using: &transform)
        setNeedsLayout()
    }

    override init(frame: CGRect) {
        pdfScale = 0
        zoomScale = 0
        shapeLayer = .init()
        shapeLayer.lineWidth = 1
        shapeLayer.bounds.size = frame.size
        shapeLayer.strokeColor = UIColor.systemRed.cgColor

        dimensionLabel = UILabel()
        dimensionLabel.translatesAutoresizingMaskIntoConstraints = false
        dimensionLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.6)
        dimensionLabel.textColor = .white

        formatter = .init()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 2

        super.init(frame: frame)

        clipsToBounds = false
        layer.addSublayer(shapeLayer)
        addSubview(dimensionLabel)
        NSLayoutConstraint.activate([
            dimensionLabel.topAnchor.constraint(equalToSystemSpacingBelow: bottomAnchor, multiplier: 1),
            dimensionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("NSCoding is not supported")
    }

    private let shapeLayer: CAShapeLayer
    private let dimensionLabel: UILabel
    private let formatter: MeasurementFormatter
}

// MARK: - Page View:

private class MeasurementDisplayingPageView: PDFPageView {
    private var measureViewReusePool = [SpreadMeasurementView]()
    private var visibleMeasureViews = [SpreadMeasurementView]()

    override func prepareForReuse() {
        visibleMeasureViews.forEach { view in
            view.isHidden = true
            view.prepareForReuse()
        }
        measureViewReusePool.append(contentsOf: visibleMeasureViews)
        visibleMeasureViews.removeAll(keepingCapacity: true)

        super.prepareForReuse()
    }

    func dequeueMeasureView() -> SpreadMeasurementView {
        let view = measureViewReusePool.popLast() ?? SpreadMeasurementView()
        view.isHidden = false
        // Ensure the measure view is added to the annotation container view - PDFPageView.prepareForReuse()
        // removes it from the view hierarchy. Also, make sure the view has the correct scales set, so it
        // displays correctly.
        annotationContainerView.addSubview(view)
        visibleMeasureViews.append(view)
        view.pdfScale = scaleForPageView
        view.zoomScale = zoomView?.zoomScale ?? 1

        return view
    }

    func markForReuse(measureView: SpreadMeasurementView) {
        measureView.prepareForReuse()
        measureView.isHidden = true
        visibleMeasureViews.removeAll {
            $0 === measureView
        }
        measureViewReusePool.append(measureView)
    }
}

// MARK: - Integration:

private class MeasuringPDFControllerManager: NSObject, PDFViewControllerDelegate {
    var measurementsSource: DocumentMeasurementDatasource?
    let documentViewController: PDFViewController
    var document: Document? {
        get { documentViewController.document }
        set {
            if newValue == nil {
                measurementsSource = nil
                documentViewController.document = nil
            } else if documentViewController.document !== newValue {
                // <# create a new measurements datasource for this document here! #>
                measurementsSource = newValue.map(MeasurementStore.init(document:)) // this line is removed from guide
                // then:
                documentViewController.document = newValue
            }
        }
    }

    override init() {
        documentViewController = PDFViewController { builder in
            builder.pageTransition = .scrollContinuous
            builder.pageMode = .double
            builder.scrollDirection = .vertical
            builder.overrideClass(PDFPageView.self, with: MeasurementDisplayingPageView.self)
        }
        super.init()
        documentViewController.delegate = self
    }

    func pdfViewController(_ pdfController: PDFViewController, didConfigurePageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        guard
            let page = pageView as? MeasurementDisplayingPageView,
            let allMeasurements = measurementsSource?.measurements(at: pageIndex)
        else {
            return
        }

        for measurement in allMeasurements
        // a measurement can span multiple pages => make sure we don’t add one to more than one page at once
        where measurement.pageRange.location == pageIndex {
            let view = page.dequeueMeasureView()
            view.measurement = measurement
        }

        /*
         Ensure the second page in a spread is always below the first one in the hierarchy, to allow measurements to
         reach across the page binding.
         */
        if pdfController.configuration.pageMode == .double && pageIndex % 2 == 0 {
            page.superview?.sendSubviewToBack(page)
        }
    }
}
