//
//  Copyright © 2017-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class ExitDrawingModeAutomaticallyExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Exit drawing mode automatically"
        contentDescription = "Exit drawing mode automatically after a line has been drawn."
        category = .annotations
        priority = 201
    }

    private weak var pdfController: PDFViewController?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .welcome)
        let pdfController = PDFViewController(document: document)
        self.pdfController = pdfController

        // Example doesn’t have a cleanup callback. Avoid registering twice when opening and closing this example two times.
        NotificationCenter.default.removeObserver(self, name: .PSPDFAnnotationsAdded, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(annotationsAdded), name: .PSPDFAnnotationsAdded, object: nil)

        return pdfController
    }

    @objc private func annotationsAdded(_ notification: Notification) {
        // Example doesn’t have a cleanup callback. The weak reference being nil shows if another example is generating this notification.
        guard let pdfController else {
            NotificationCenter.default.removeObserver(self, name: .PSPDFAnnotationsAdded, object: nil)
            return
        }

        // bail out if this is for another controller (e.g. split screen)
        // or if this inserts another annotation type.
        guard let annotation = (notification.object as? NSArray)?.firstObject as? InkAnnotation, annotation.document == pdfController.document else {
            return
        }

        // if we are in drawing mode and a new ink annotation is added, finish it.
        if pdfController.annotationStateManager.state == .ink {
            pdfController.annotationStateManager.state = nil
        }
    }
}
