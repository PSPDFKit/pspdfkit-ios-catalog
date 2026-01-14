//
//  Copyright © 2017-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class DocumentPickerSidebarExample: Example {

    override init() {
        super.init()

        title = "Document Picker Sidebar"
        contentDescription = "Displays a Document Picker in the sidebar."
        category = .top
        priority = 5
        wantsModalPresentation = true
        embedModalInNavigationController = false
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        return PSCSplitViewController()
    }
}
