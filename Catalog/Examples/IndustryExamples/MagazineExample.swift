//
//  Copyright © 2017-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// This example uses the following Nutrient features:
/// - Viewer
///
/// See https://www.nutrient.io/sdk/ios for the complete list of Nutrient iOS SDK’s features.

class MagazineExample: IndustryExample {

    var pdfController: PDFViewController!

    override init() {
        super.init()

        title = "Magazine"
        contentDescription = "Shows how to configure Nutrient to display a magazine."
        category = .industryExamples
        targetDevice = [.vision, .phone, .pad]
        priority = 3
        extendedDescription = """
        This example shows how to configure document viewing options, like the curl page transition, for reading a magazine.

        It also shows how to disable editing and annotating a document to allow a read-only experience.

        And finally, this example shows how to restrict text extraction to prevent readers from redistributing paid content.
        """
        url = URL(string: "https://www.nutrient.io/blog/industry-solution-magazine-ios/")!
        image = UIImage(systemName: "newspaper")
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        return MagazinePDFViewController(with: self)
    }
}

private class MagazinePDFViewController: PDFViewController, PDFViewControllerDelegate {

    /// Used for showing the more info alert.
    private var moreInfo: MoreInfoCoordinator!

    init(with example: IndustryExample) {
        let document = AssetLoader.writableDocument(for: .magazine, overrideIfExists: false)
        document.uid = "Magazine" // Set custom UID so it doesn't interfere with other examples.
        document.title = "BORA" // Override document title.

        let configuration = PDFConfiguration {
            // Configure the document presentation options.
            // See https://www.nutrient.io/guides/ios/customizing-the-interface/document-presentation-options/ for more details.
            $0.pageTransition = .curl
            $0.pageMode = .automatic
            $0.scrollDirection = .horizontal
            $0.isFirstPageAlwaysSingle = true

            // Disable selecting images but leave selecting text enabled.
            $0.isImageSelectionEnabled = false

            // Disable the modification of all annotation types.
            // See https://www.nutrient.io/guides/ios/features/controlling-pdf-editing/#disabling-the-modification-of-all-annotation-types for more details.
            $0.editableAnnotationTypes = .none

            // Miscellaneous configuration options.
            $0.userInterfaceViewAnimation = .slide
            $0.thumbnailBarMode = .scrollable
        }

        super.init(document: document, configuration: configuration)

        // Only show the outlines in the document info.
        // See https://www.nutrient.io/guides/ios/customizing-the-interface/customizing-the-available-document-information/ for more details.
        pdfController.documentInfoCoordinator.availableControllerOptions = [.outline]

        // Customize the toolbar.
        // See https://www.nutrient.io/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)

        #if os(visionOS)
        setMainToolbarOrnamentItems([backOrnamentItem, moreInfo.barOrnamentItem, titleOrnamentItem, OrnamentItem(kind: .divider), settingsOrnamentItem, bookmarkOrnamentItem, outlineOrnamentItem, searchOrnamentItem], for: .document)
        #else
        navigationItem.leftBarButtonItems = [moreInfo.barButton, pdfController.brightnessButtonItem]
        navigationItem.rightBarButtonItems = [bookmarkButtonItem, outlineButtonItem, searchButtonItem]
        navigationItem.leftItemsSupplementBackButton = true
        #endif

        userInterfaceView.pageLabel.showThumbnailGridButton = true

        // Hide specific option on thumbnail filter bar
        thumbnailController.filterOptions = [.showAll, .bookmarks]

        // We need this to customize the menus.
        delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

    func pdfViewController(_ sender: PDFViewController, menuForText glyphs: GlyphSequence, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        // Keep the entire Look Up and Speech menus.
        suggestedMenu
            .keep(menus: [.lookup, .speech], actions: [])
    }

}
