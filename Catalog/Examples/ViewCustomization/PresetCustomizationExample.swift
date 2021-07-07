//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class PresetCustomizationExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()
        title = "Preset Customization Example"
        contentDescription = "Shows how to override default color presets."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Configure custom default presets.
        let presets = [
            ColorPreset(color: UIColor.black),
            ColorPreset(color: UIColor.red),
            ColorPreset(color: UIColor.orange),
            ColorPreset(color: UIColor.blue),
            ColorPreset(color: UIColor.purple)
        ]
        let styleManager = SDK.shared.styleManager
        let key = Annotation.ToolVariantID(tool: .line)
        styleManager.setDefaultPresets(presets, forKey: key, type: .colorPreset)

        // NOTE: Users can change the styles in the inspector unless you change
        // PSPDFAnnotationStyleViewControllerDelegate.persistsColorPresetChanges.

        // Setup controller
        let document = AssetLoader.document(for: .quickStart)

        // Add a sample line
        let line = LineAnnotation(point1: CGPoint(x: 50, y: 50), point2: CGPoint(x: 200, y: 200))
        document.add(annotations: [line])

        let pdfController = PDFViewController(document: document, delegate: self)
        return pdfController
    }

    // MARK: PDFViewControllerDelegate

    internal func pdfViewController(_ pdfController: PDFViewController, didConfigurePageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        // Preselect the line.
        if pageView.pageIndex == 0 {
            pageView.selectedAnnotations = pdfController.document?.annotationsForPage(at: 0, type: .line)
        }
    }

    func pdfViewControllerDidDismiss(_ pdfController: PDFViewController) {
        // Restore default presets to not affect other examples.
        let styleManager = SDK.shared.styleManager
        let key = Annotation.ToolVariantID(tool: .line)
        styleManager.setDefaultPresets(nil, forKey: key, type: .colorPreset)
    }
}
