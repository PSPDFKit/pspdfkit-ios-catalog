//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

class SettingsExample: Example {

    override init() {
        super.init()

        self.title = "Settings"
        self.contentDescription = "Use PDFSettingsViewController to customize key UX elements."
        self.type = "com.pspdfkit.catalog.default"
        self.category = .barButtons
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        SDK.shared[.debugMode] = true

        let document = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: document) {
            $0.settingsOptions = .all
        }
        controller.navigationItem.rightBarButtonItems = [controller.thumbnailsButtonItem, controller.settingsButtonItem]

        return controller
    }
}
