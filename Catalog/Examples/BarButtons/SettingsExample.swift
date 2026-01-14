//
//  Copyright © 2015-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class SettingsExample: Example {

    override init() {
        super.init()

        self.title = "Settings"
        self.contentDescription = "Use PDFSettingsViewController to customize key UX elements."
        self.category = .barButtons
        priority = 230
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        SDK.shared[.debugMode] = true

        let document = AssetLoader.document(for: .welcome)
        let controller = PDFViewController(document: document) {
            $0.settingsOptions = .all
        }
        controller.navigationItem.rightBarButtonItems = [controller.thumbnailsButtonItem, controller.settingsButtonItem]

        return controller
    }
}
