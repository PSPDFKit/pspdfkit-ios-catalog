//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

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
        navigationItem.leftItemsSupplementBackButton = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBarButtonItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.window?.windowScene?.screenshotService?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if view.window?.windowScene?.screenshotService?.delegate === self {
            view.window?.windowScene?.screenshotService?.delegate = nil
        }
    }

    // MARK: Customization

    private var isWide: Bool {
        (traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular)
        || (traitCollection.userInterfaceIdiom == .phone && traitCollection.verticalSizeClass == .compact)
    }

    private func updateBarButtonItems() {
        // Show more items on wide screens. The order we're setting the items
        // matters, because we're moving some buttons that are on the right side
        // to the left side. They need to be removed first before being added to
        // the other side.
        if isWide {
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, activityButtonItem, annotationButtonItem, searchButtonItem], for: .document, animated: false)
            navigationItem.setLeftBarButtonItems([settingsButtonItem, outlineButtonItem], for: .document, animated: false)
        } else {
            navigationItem.setLeftBarButtonItems([], for: .document, animated: false)
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, activityButtonItem, annotationButtonItem, settingsButtonItem], for: .document, animated: false)
        }
    }

    private func updateTitle() {
        // Show both the custom document title and file name on wide screens.
        if isWide {
            guard let document = document, let documentTitle = document.title else { return }
            guard let fileName = document.fileURL?.deletingPathExtension().lastPathComponent, fileName != documentTitle else { return }
            title = "\(documentTitle) (\(fileName))"
        }
    }

    // MARK: Delegates

    func pdfViewController(_ pdfController: PDFViewController, didChange document: Document?) {
        updateTitle()
    }

}
