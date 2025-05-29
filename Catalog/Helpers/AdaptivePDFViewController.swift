//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// A slightly customized version of `PDFViewController`, adding more bar button
/// items and using a full document title.
@objc(PSCAdaptivePDFViewController)
class AdaptivePDFViewController: PDFViewController, PDFViewControllerDelegate {

    // MARK: Lifecycle

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)
        delegate = self
        // Bar button items and title depend on screen width.
        setUpdateSettingsForBoundsChange { [weak self] _ in
            self?.updateBarButtonItems()
            self?.updateTitle()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setLeftItemsSupplementBackButton(true, for: .document)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBarButtonItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if !os(visionOS)
        view.window?.windowScene?.screenshotService?.delegate = self
        #endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if view.window?.windowScene?.screenshotService?.delegate === self {
            view.window?.windowScene?.screenshotService?.delegate = nil
        }
    }

    // MARK: Customization

    private var isWide: Bool {
        // 440 pt is the minimum space needed for the 6 bar buttons we want plus the back button.
        view.bounds.inset(by: view.safeAreaInsets).width > 440
    }

    private func updateBarButtonItems() {
        // Show more items on wide screens. The order we're setting the items
        // matters, because we're moving some buttons that are on the right side
        // to the left side. They need to be removed first before being added to
        // the other side.
        if isWide {
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, activityButtonItem, contentEditingButtonItem, annotationButtonItem, searchButtonItem], for: .document, animated: false)
            navigationItem.setLeftBarButtonItems([settingsButtonItem, outlineButtonItem], for: .document, animated: false)
        } else {
            navigationItem.setLeftBarButtonItems([], for: .document, animated: false)
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, activityButtonItem, contentEditingButtonItem, annotationButtonItem, settingsButtonItem], for: .document, animated: false)
        }
    }

    private func updateTitle() {
        // Show both the custom document title and file name on wide screens.
        if isWide {
            guard let document, let documentTitle = document.title else { return }
            guard let fileName = document.fileURL?.deletingPathExtension().lastPathComponent, fileName != documentTitle else { return }
            title = "\(documentTitle) (\(fileName))"
        }
    }

    // MARK: Delegates

    func pdfViewController(_ pdfController: PDFViewController, didChange document: Document?) {
        updateTitle()
    }

}
