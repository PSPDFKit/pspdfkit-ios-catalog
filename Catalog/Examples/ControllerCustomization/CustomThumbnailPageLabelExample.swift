//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CustomThumbnailPageLabelExample: Example {

    override init() {
        super.init()
        title = "Custom Thumbnail Page Label"
        contentDescription = "Shows how to customize page labels in the thumbnails view mode."
        category = .controllerCustomization
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        // Set custom appearance only to the custom subclass so that we don't
        // overrde all examples here. In your code, you can use ThumbnailGridViewCell.
        let appearance = RoundedLabel.appearance(whenContainedInInstancesOf: [CustomThumbnailGridViewCell.self])
        appearance.rectColor = UIColor.systemGreen.withAlphaComponent(0.8)
        appearance.cornerRadius = 20
        // Register our custom cell as a subclass.
        let controller = PDFViewController(document: AssetLoader.document(for: .welcome)) {
            $0.overrideClass(ThumbnailGridViewCell.self, with: CustomThumbnailGridViewCell.self)
        }
        // Switch to the thumbnails mode immediately.
        controller.viewMode = .thumbnails
        return controller
    }

}

private class CustomThumbnailGridViewCell: ThumbnailGridViewCell {

    override func updatePageLabel() {
        super.updatePageLabel()
        // You can customize the page label here as well.
    }

}
