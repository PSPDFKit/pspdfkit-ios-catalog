//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class FloatingStampsExample: Example {

    override init() {
        super.init()

        title = "Floating Stamps"
        contentDescription = "Stamp annotations that have a fixed size and do not zoom with the page."
        category = .annotations
        priority = 2000
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        // Register our custom annotation provider as a subclass before any action with a document is carried out.
        // All stamp annotations added to this document using the example will not be zoomed in.
        document.overrideClass(PDFFileAnnotationProvider.self, with: NoZoomAnnotationProvider.self)

        let controller = PDFViewController(document: document)

        return controller
    }
}

private class NoZoomAnnotationProvider: PDFFileAnnotationProvider {

    override func add(_ annotations: [Annotation], options: [AnnotationManager.ChangeBehaviorKey: Any]? = nil) -> [Annotation]? {
        // Add the `noZoom` flag to all stamp annotations so they are not zoomed with the page.
        for annotation in annotations where annotation is StampAnnotation {
            annotation.flags.update(with: .noZoom)
        }
        return super.add(annotations, options: options)
    }
}
