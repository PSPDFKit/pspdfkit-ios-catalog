//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// This example uses the following PSPDFKit features:
/// - Viewer
///
/// See https://pspdfkit.com/pdf-sdk/ios/ for the complete list of features for PSPDFKit for iOS.

class MagazineExample: IndustryExample {

    var pdfController: PDFViewController!

    override init() {
        super.init()

        title = "Magazine"
        contentDescription = "Shows how to configure PSPDFKit to display a magazine."
        category = .industryExamples
        priority = 3
        extendedDescription = """
        This example shows how to configure document viewing options, like the curl page transition, for reading a magazine.

        It also shows how to disable editing and annotating a document to allow a read-only experience.

        And finally, this example shows how to restrict text extraction to prevent readers from redistributing paid content.
        """
        url = URL(string: "https://pspdfkit.com/blog/2021/industry-solution-magazine-ios/")!
        if #available(iOS 14.0, *) {
            image = UIImage(systemName: "newspaper")
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        return MagazinePDFViewController(with: self)
    }
}

private class MagazinePDFViewController: PDFViewController {

    /// Used for showing the more info alert.
    private var moreInfo: MoreInfoCoordinator!

    init(with example: IndustryExample) {
        let document = AssetLoader.writableDocument(for: .magazine, overrideIfExists: false)
        document.uid = "Magazine" // Set custom UID so it doesn't interfere with other examples.
        document.title = "BORA" // Override document title.

        let configuration = PDFConfiguration {
            // Configure the document presentation options.
            // See https://pspdfkit.com/guides/ios/customizing-the-interface/document-presentation-options/ for more details.
            $0.pageTransition = .curl
            $0.pageMode = .automatic
            $0.scrollDirection = .horizontal
            $0.isFirstPageAlwaysSingle = true

            // Disable the modification of all annotation types.
            // See https://pspdfkit.com/guides/ios/features/controlling-pdf-editing/#disable-the-modification-of-all-annotation-types for more details.
            $0.editableAnnotationTypes = .none

            // Only show the define and speak menus.
            // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-menus/ for more details.
            $0.allowedMenuActions = [.define, .speak]

            // Miscellaneous configuration options.
            $0.userInterfaceViewAnimation = .slide
            $0.thumbnailBarMode = .scrollable
        }

        super.init(document: document, configuration: configuration)

        // Only show the outlines in the document info.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-available-document-information/ for more details.
        pdfController.documentInfoCoordinator.availableControllerOptions = [.outline]

        // Customize the toolbar.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        navigationItem.leftBarButtonItems = [moreInfo.barButton, pdfController.brightnessButtonItem]
        navigationItem.rightBarButtonItems = [bookmarkButtonItem, outlineButtonItem, searchButtonItem]
        navigationItem.leftItemsSupplementBackButton = true

        userInterfaceView.pageLabel.showThumbnailGridButton = true

        // Hide specific option on thumbnail filter bar
        thumbnailController.filterOptions = [.showAll, .bookmarks]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

}
