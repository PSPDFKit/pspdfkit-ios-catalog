//
//  Copyright © 2017-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class AnnotationLinkEditorExample: Example {

    override init() {
        super.init()

        title = "Annotation Link Editor"
        contentDescription = "Shows how to create link annotations."
        category = .annotations
        priority = 71
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        let controller = PDFViewController(document: document) {
            // Only allow adding link annotations here
            $0.editableAnnotationTypes = [.link]
        }
        return controller
    }
}
