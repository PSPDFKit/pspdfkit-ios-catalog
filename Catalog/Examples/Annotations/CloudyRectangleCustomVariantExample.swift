//
//  Copyright © 2023-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CloudyRectangleCustomVariantExample: Example {

    override init() {
        super.init()

        title = "Cloudy rectangle tool (custom annotation variant)"
        contentDescription = "Shows side-by-side tools for creating straight rectangles and cloudy rectangles by setting up a custom tool variant."
        category = .annotations
        priority = 999
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Define a string to identify our custom tool variant.
        let cloudyRectangleVariant = Annotation.Variant(rawValue: "MyCustomCloudyRectangle")

        // Set the initial style to use a cloudy border. For simplicity, this example sets this every time but this info is persisted so usually you only want to set this once otherwise each time the app is run you might be overwriting the user’s last used styles.
        let cloudyRectangleID = Annotation.ToolVariantID(tool: .square, variant: cloudyRectangleVariant)
        PSPDFKit.SDK.shared.styleManager.setLastUsedValue(Annotation.BorderEffect.cloudy.rawValue, forProperty: #keyPath(Annotation.borderEffect), forKey: cloudyRectangleID)
        PSPDFKit.SDK.shared.styleManager.setLastUsedValue(2, forProperty: #keyPath(Annotation.borderEffectIntensity), forKey: cloudyRectangleID)

        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let pdfViewController = PDFViewController(document: document)

        // Define our tools for the annotation toolbar.
        let straightRectangleTool = AnnotationToolConfiguration.ToolItem(type: .square)
        let cloudyRectangleTool = AnnotationToolConfiguration.ToolItem(type: .square, variant: cloudyRectangleVariant) { _, _, _ in
            UIImage(namedInCatalog: "rectangle_cloudy")!
        }

        // Tell the annotation toolbar to use these tools.
        // In practice, you probably want more tools and want to set multiple configurations to adapt to different amounts of space available. See `MeasurementsExample` for an example.
        pdfViewController.annotationToolbarController!.annotationToolbar.configurations = [
            AnnotationToolConfiguration(annotationGroups: [
                AnnotationToolConfiguration.ToolGroup(items: [straightRectangleTool]),
                AnnotationToolConfiguration.ToolGroup(items: [cloudyRectangleTool]),
            ]),
        ]

        return pdfViewController
    }
}
