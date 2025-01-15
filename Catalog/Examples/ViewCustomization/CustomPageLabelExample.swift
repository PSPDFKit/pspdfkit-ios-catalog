//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

private class CustomPageLabelFormatter: PageLabelFormatter {
    override func string(from pageRange: NSRange) -> String {
        return "Custom Page Label: \(pageRange.location + 1)"
    }
}

class CustomPageLabelExample: Example {
    override init() {
        super.init()

        title = "Custom Page Label Example"
        contentDescription = "Shows how to customize page labels."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .annualReport)
        let controller = PDFViewController(document: document) {
            $0.pageMode = .single
        }
        // Set the custom label formatter
        controller.userInterfaceView.pageLabel.labelFormatter = CustomPageLabelFormatter()
        return controller
    }
}
