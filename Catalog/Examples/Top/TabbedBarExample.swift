//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class TabbedBarExample: Example {

    override init() {
        super.init()

        title = "Tabbed Bar"
        contentDescription = "Opens multiple documents in a tabbed interface."
        category = .top
        targetDevice = [.vision, .phone, .pad]
        priority = 3
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        return TabbedExampleViewController()
    }
}

class TabbedExampleViewController: PDFTabbedViewController, PDFTabbedViewControllerDelegate {
    var clearTabsButtonItem = UIBarButtonItem()

    override func commonInit(withPDFController pdfController: PDFViewController?) {
        super.commonInit(withPDFController: pdfController)

        // In case pdfController was nil and commonInitWithPDFController created it.
        let controller = self.pdfController
        delegate = self

        navigationItem.leftItemsSupplementBackButton = true

        allowDraggingTabsToExternalTabbedBar = true
        allowDroppingTabsFromExternalTabbedBar = true

        let samplesURL = FileHelper.copySamplesToDocumentDirectory(overwrite: true)
        documentPickerController = PDFDocumentPickerController(directory: samplesURL.path, includeSubdirectories: true, library: SDK.shared.library)

        clearTabsButtonItem = UIBarButtonItem(image: SDK.imageNamed("trash"), style: .plain, target: self, action: #selector(clearTabsButtonPressed(sender:)))

        controller.barButtonItemsAlwaysEnabled = [clearTabsButtonItem]
        controller.navigationItem.setLeftBarButtonItems([clearTabsButtonItem], for: .document, animated: false)

        controller.setUpdateSettingsForBoundsChange { [weak self] _ in
            self?.updateBarButtonItems()
        }

        // Show some documents initially. You can open more using the + button at the left end of the tabbed bar.
        documents = [AssetName.welcome, AssetName.psychologyResearch, AssetName.cosmicContextForLife].map {
            Document(url: samplesURL.appendingPathComponent($0.rawValue))
        }

        NotificationCenter.default.addObserver(self, selector: #selector(documentOpenedInNewSceneNotification(_:)), name: .PSCDocumentOpenedInNewScene, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBarButtonItems()
    }

    override func addDocument(_ document: Document, makeVisible shouldMakeDocumentVisible: Bool, animated: Bool) {
        super.addDocument(document, makeVisible: shouldMakeDocumentVisible, animated: animated)
        document.userActivity = userActivity(for: document)
    }

    override var documents: [Document] {
        didSet {
            for document in documents {
                document.userActivity = userActivity(for: document)
            }
        }
    }

    private func userActivity(for document: Document) -> NSUserActivity? {
        guard let fileURL = document.fileURL else { return nil }
        return NSUserActivity.openDocumentActivity(forFileURL: fileURL)
    }

    // MARK: - Private

    @objc func clearTabsButtonPressed(sender: UIBarButtonItem) {
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheetController.addAction(UIAlertAction(title: "Close All Tabs", style: UIAlertAction.Style.destructive, handler: { [weak self] _ in
            self?.documents = []
        }))
        let popoverPresentation = sheetController.popoverPresentationController
        popoverPresentation?.barButtonItem = sender

        present(sheetController, animated: true)
    }

    func updateBarButtonItems() {
        let controller = self.pdfController

        var items = [controller.thumbnailsButtonItem, controller.activityButtonItem, controller.annotationButtonItem, controller.contentEditingButtonItem]
        // Add more items if we have space available
        if traitCollection.horizontalSizeClass == .regular {
            items.insert(controller.outlineButtonItem, at: 2)
            items.insert(controller.searchButtonItem, at: 2)
        }
        controller.navigationItem.setRightBarButtonItems(items, for: .document, animated: false)
    }

    func updateToolbarItems() {
        clearTabsButtonItem.isEnabled = !documents.isEmpty
    }

    internal func multiPDFController(_ multiPDFController: MultiDocumentViewController, didChange oldDocuments: [Document]) {
        updateToolbarItems()
    }

    @objc func documentOpenedInNewSceneNotification(_ notification: Notification) {
        guard let url = notification.userInfo?["documentURL"] as? URL else { return }
        for document in self.documents where url.resolvingSymlinksInPath() == document.fileURL?.resolvingSymlinksInPath() {
            self.removeDocument(document, animated: true)
        }
    }
}
