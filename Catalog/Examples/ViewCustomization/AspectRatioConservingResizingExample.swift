//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class AspectRatioConservingResizingExample: Example {

    override init() {
        super.init()
        title = "Aspect Ratio Conserving Example"
        contentDescription = "Shows how to implement resizing that always preserves the annotation aspect ratio."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .annualReport)

        // Add free text
        let freeText = FreeTextAnnotation()
        freeText.fontSize = 30
        freeText.contents = "Example text. Drag me!"
        freeText.boundingBox = CGRect(x: 50, y: 50, width: 300, height: 300)
        freeText.sizeToFit()
        freeText.color = UIColor.blue
        freeText.absolutePageIndex = 0
        document.add(annotations: [freeText])

        let pdfController = PDFViewController(document: document, delegate: self) {
            $0.overrideClass(ResizableView.self, with: AspectResizableView.self)
        }
        return pdfController
    }

    // MARK: Resizable view customization

    private class AspectResizableView: ResizableView {

        // MARK: Lifecycle

        override init(frame: CGRect) {
            super.init(frame: frame)
            customize()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            customize()
        }

        // MARK: Knob customization

        private func customize() {
            // Always snap to guide.
            guideSnapAllowance = PSPDFGuideSnapAllowanceAlways
            // Remove all knobs but the bottom right one.
            let range = ResizableView.OuterKnob.topLeft.rawValue...ResizableView.OuterKnob.bottomRight.rawValue
            let knobTypes = range.compactMap { ResizableView.OuterKnob(rawValue: $0) }
            for knobType in knobTypes {
                outerKnob(ofType: knobType)?.removeFromSuperview()
            }
        }
    }
}

// MARK: PDFViewControllerDelegate

extension AspectRatioConservingResizingExample: PDFViewControllerDelegate {

    internal func pdfViewController(_ pdfController: PDFViewController, didConfigurePageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        if pageView.pageIndex == 0 {
            pageView.selectedAnnotations = pdfController.document?.annotations(at: 0, type: FreeTextAnnotation.self)
        }
    }
}
