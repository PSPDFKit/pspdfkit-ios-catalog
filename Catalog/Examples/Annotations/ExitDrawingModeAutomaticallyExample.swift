//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
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

    // store observer for later removal (if needed)
    private var observer: Any?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = PDFViewController(document: document)

        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsAdded, object: nil, queue: OperationQueue.main) { [weak pdfController] notification in
            guard let pdfController = pdfController else { return }

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

        return pdfController
    }
}
