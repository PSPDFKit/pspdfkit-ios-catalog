//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// This example uses the following PSPDFKit features:
/// - Viewer
/// - Annotations
/// - Document Editor
/// - Reader View
///
/// See https://pspdfkit.com/pdf-sdk/ios/ for the complete list of features for PSPDFKit for iOS.

class EreaderExample: IndustryExample {

    var pdfController: PDFViewController!

    override init() {
        super.init()

        title = "E-Reader"
        contentDescription = "Shows how to configure PSPDFKit as an e-reader."
        category = .industryExamples
        priority = 4
        wantsModalPresentation = true
        customizations = { container in
            container.modalPresentationStyle = .fullScreen
        }
        extendedDescription = "This example shows how to customize document viewing options to create an optimum user experience for reading research papers."
        url = URL(string: "https://pspdfkit.com/blog/2021/industry-solution-ereader-ios/")!
        if #available(iOS 14.0, *) {
            image = UIImage(systemName: "doc.richtext")
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        return EreaderPDFViewController(with: self)
    }
}

private class EreaderPDFViewController: PDFViewController {

    /// Used for showing the more info alert.
    private var moreInfo: MoreInfoCoordinator!

    init(with example: IndustryExample) {
        let document = AssetLoader.writableDocument(for: .psychologyResearch, overrideIfExists: false)
        document.autodetectTextLinkTypes = .all

        let configuration = PDFConfiguration {
            // Configure the document presentation options.
            // See https://pspdfkit.com/guides/ios/customizing-the-interface/document-presentation-options/ for more details.
            $0.pageTransition = .scrollContinuous
            $0.scrollDirection = .vertical

            // Miscellaneous configuration options.
            $0.isRenderAnimationEnabled = false
            $0.shouldHideNavigationBarWithUserInterface = false
            $0.shouldHideStatusBarWithUserInterface = false
        }

        super.init(document: document, configuration: configuration)

        // Customize the document view layout.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/the-document-view-hierarchy/#customizing-the-layout for more details.
        if let layout = pdfController.documentViewController?.layout as? ContinuousScrollingLayout {
            layout.fillAlongsideTransverseAxis = true
        }

        // Customize the toolbar.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
        navigationItem.setLeftBarButtonItems([moreInfo.barButton, brightnessButtonItem, readerViewButtonItem], for: .document, animated: false)
        navigationItem.setRightBarButtonItems([thumbnailsButtonItem, searchButtonItem, outlineButtonItem, activityButtonItem, annotationButtonItem], for: .document, animated: false)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }
}
