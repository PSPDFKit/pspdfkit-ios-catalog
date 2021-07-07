//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class AnnotationInspectorBlendModeStampExample: Example {

    override init() {
        super.init()

        title = "Configure the annotation Inspector to set Blend Mode for stamp annotations"
        contentDescription = "Shows how to customize the annotation Inspector to set Blend Mode for vector stamp annotations."
        category = .annotations
        priority = 203
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        document.annotationSaveMode = .embedded

        // Add stamp annotation if there isn't one already.
        let pageIndex: PageIndex = 0
        let stamps = document.annotationsForPage(at: pageIndex, type: .stamp)
        if stamps.isEmpty {
            let logoURL = AssetLoader.assetURL(for: "PSPDFKit Logo.pdf")
            let stampAnnotation = StampAnnotation()
            stampAnnotation.boundingBox = CGRect(x: 180.0, y: 150.0, width: 444.0, height: 500.0)
            stampAnnotation.appearanceStreamGenerator = FileAppearanceStreamGenerator(fileURL: logoURL)
            stampAnnotation.pageIndex = pageIndex
            document.add(annotations: [stampAnnotation])
        }

        let controller = BlendModeInspectorForStampsViewController(document: document) {
            // Do not show color presets.
            var typesShowingColorPresets = $0.typesShowingColorPresets
            typesShowingColorPresets.remove(.stamp)
            $0.typesShowingColorPresets = typesShowingColorPresets

            // Configure the properties for stamp annotations to show the blend mode setting in the annotation Inspector.
            var properties = $0.propertiesForAnnotations
            properties[.stamp] = [[AnnotationStyle.Key.blendMode]]
            $0.propertiesForAnnotations = properties
        }
        return controller
    }
}

private class BlendModeInspectorForStampsViewController: PDFViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Select the stamp annotation to show the Inspector menu.
        let pageView = self.pageViewForPage(at: 0)
        guard let stampAnnotation = self.document?.annotationsForPage(at: pageIndex, type: .stamp).first else { return }
        pageView?.select(stampAnnotation, animated: true)
    }
}
