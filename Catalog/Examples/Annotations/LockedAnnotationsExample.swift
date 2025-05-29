//
//  Copyright © 2020-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class LockedAnnotationsExample: Example {
    override init() {
        super.init()

        title = "Lock specific annotations"
        contentDescription = "Example how to lock specific annotations. All black annotations cannot be moved anymore."
        category = .annotations
        priority = 110
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: AssetName.welcome)

        document.annotationSaveMode = .disabled

        // Add some test annotations.
        let ink = InkAnnotation.sampleInkAnnotation(in: CGRect(x: 100, y: 100, width: 200, height: 200))
        ink.color = UIColor.green
        let ink2 = InkAnnotation.sampleInkAnnotation(in: CGRect(x: 300.0, y: 300.0, width: 200.0, height: 200.0))
        ink2.color = UIColor.black
        let ink3 = InkAnnotation.sampleInkAnnotation(in: CGRect(x: 100.0, y: 400.0, width: 200.0, height: 200.0))
        ink3.color = UIColor.red
        document.add(annotations: [ink, ink2, ink3], options: nil)

        let controller = LockedAnnotationsViewController(document: document) {
            $0.overrideClass(PDFPageView.self, with: LockedAnnotationsPageView.self)
        }
        return controller
    }
}

private class LockedAnnotationsViewController: PDFViewController {
    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        // Dynamically change selection mode if an annotation changes.
        NotificationCenter.default.addObserver(self, selector: #selector(annotationsChangedNotification(notification:)), name: .PSPDFAnnotationChanged, object: nil)
    }

    @objc func annotationsChangedNotification(notification: Notification) {
        // Reevaluate all page views. Usually there's just one but this is more future-proof.
        for pageView in visiblePageViews {
            pageView.updateAnnotationSelectionView()
        }
    }
}

private class LockedAnnotationsPageView: PDFPageView {
    override func didSelect(_ annotations: [Annotation]) {
        updateAnnotationSelectionView()
    }

    override func updateAnnotationSelectionView() {
        let isBlackAnnotationIsSelected = selectedAnnotations.contains {
            // Comparing colors is always tricky - we use a helper and allow some leeway.
            // The helper also deals with details like different color spaces.
            UIColor.isColorAboutEqual($0.color, to: .black, tolerance: 0.1)
        }
        annotationSelectionView?.allowEditing = isBlackAnnotationIsSelected == false
    }
}
