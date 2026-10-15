//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// A subclass of `PDFViewController` that adds more buttons in the main toolbar.
@objc(PSCAdaptivePDFViewController)
class AdaptivePDFViewController: PDFViewController {

    /// The buttons to use on the trailing side where there is enough space.
    private lazy var preferredRightBarButtonItems = [thumbnailsButtonItem, readerViewButtonItem, contentEditingButtonItem, settingsButtonItem, bookmarkButtonItem, aiAssistantButtonItem, activityButtonItem, annotationButtonItem]

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        navigationItem.setLeftItemsSupplementBackButton(true, for: .document)
        // Buttons can’t be on both sides, so first remove all trailing buttons.
        navigationItem.setRightBarButtonItems([], for: .document, animated: false)
        // Always show these two buttons on the leading side.
        navigationItem.setLeftBarButtonItems([outlineButtonItem, searchButtonItem], for: .document, animated: false)

        if #available(iOS 26, *) {
            // iOS 26 automatically collapses bar button items into an overflow menu when running out of space.
            navigationItem.setRightBarButtonItems(preferredRightBarButtonItems, for: .document, animated: false)
        } else {
            // On older versions, manually remove some bar buttons based on the available width.
            setUpdateSettingsForBoundsChange { [weak self] _ in
                self?.updateBarButtonItems()
            }
        }
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)

        if #unavailable(iOS 26) {
            updateBarButtonItems()
        }
    }

    private func updateBarButtonItems() {
        if view.bounds.inset(by: view.safeAreaInsets).width > 550 {
            navigationItem.setRightBarButtonItems(preferredRightBarButtonItems, for: .document, animated: false)
        } else {
            // Remove some less important buttons when there isn’t enough space.
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, activityButtonItem, annotationButtonItem], for: .document, animated: false)
        }
    }

}
