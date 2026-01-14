//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CustomThumbnailViewControllerExample: Example {
    override init() {
        super.init()

        title = "Thumbnail view controller with custom font and placeholder labels"
        contentDescription = "Customizing font and labels in the ThumbnailViewController"
        category = .subclassing

        priority = 500
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {

        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        let controller = AdaptivePDFViewController(document: document) { configuration in

            // Override the ThumbnailViewController to customize the "No bookmarks" text
            // The CustomThumbnailViewController also handles the cell override internally
            configuration.overrideClass(ThumbnailViewController.self, with: CustomThumbnailViewController.self)
        }

        return controller
    }
}

// Custom ThumbnailViewController to change "No bookmarks" text
private class CustomThumbnailViewController: ThumbnailViewController {

    override func emptyContentLabel(forFilter filter: ThumbnailViewFilter) -> String? {
        // Change the text for bookmarks and annotations to something else
        if filter == .bookmarks {
            return "You need some bookmarks here"
        }

        if filter == .annotations {
            return "Something is cooking here!"
        }
        // For other filters, use the default behavior
        return super.emptyContentLabel(forFilter: filter)
    }

    // Override the cell class property to use our custom cell
    override var cellClass: AnyClass {
        get {
            return CustomThumbnailGridViewCell.self
        }
        set {
            // Ignore attempts to set a different cell class
        }
    }

    // Override to customize the filter segment appearance
    override func updateFilterSegment() {
        super.updateFilterSegment()

        // Customize the filter segment font
        if let filterSegment = self.filterSegment {
            // Set custom font attributes for normal state
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            filterSegment.setTitleTextAttributes(normalAttributes, for: .normal)

            // Set custom font attributes for selected state
            let selectedAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.systemBlue
            ]
            filterSegment.setTitleTextAttributes(selectedAttributes, for: .selected)
        }
    }
}

// Custom ThumbnailGridViewCell to customize the pageLabel font
private class CustomThumbnailGridViewCell: ThumbnailGridViewCell {

    override func updatePageLabel() {
        super.updatePageLabel()

        // Customize the pageLabel font after it's updated
        pageLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        // You can also customize other properties:
        pageLabel.textColor = .systemBlue
    }
}
