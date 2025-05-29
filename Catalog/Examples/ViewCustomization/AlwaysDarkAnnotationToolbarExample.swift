//
//  Copyright © 2019-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class AlwaysDarkAnnotationToolbarExample: Example {

    override init() {
        super.init()

        title = "Dark Annotation Toolbar"
        contentDescription = "Customize Annotation Toolbar to always use Dark Mode UI"
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        let pdfController = PDFViewController(document: document)

        let annotationToolbar = pdfController.annotationToolbarController?.annotationToolbar

        // Set the user interface style of the annotation toolbar to dark
        // to always use the dark mode appearance.
        annotationToolbar?.overrideUserInterfaceStyle = .dark

        return pdfController
    }

}
