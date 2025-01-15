//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class SimpleAnnotationInspectorExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Simple Annotation Inspector"
        contentDescription = "Shows how to hide certain properties from the annotation inspector."
        category = .viewCustomization
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let pdfController = PDFViewController(document: document) {
            // Overrides the inspector with our own subclass to dynamically modify what properties we want to show.
            $0.overrideClass(AnnotationStyleViewController.self, with: SimpleAnnotationStyleViewController.self)
        }

        //  We use the delegate to customize the menu items.
        pdfController.delegate = self

        return pdfController
    }

}

private class SimpleAnnotationStyleViewController: AnnotationStyleViewController {

    override func properties(for annotations: [Annotation]) -> [[AnnotationStyle.Key]] {
        // Allow only a smaller list of known properties in the inspector.
        let supportedKeys: [AnnotationStyle.Key] = [.color, .alpha, .lineWidth, .fontSize]
        return super.properties(for: annotations).map {
            $0.filter { supportedKeys.contains($0) }
        }
    }

}
