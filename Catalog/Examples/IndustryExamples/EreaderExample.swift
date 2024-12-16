//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// This example uses the following Nutrient features:
/// - Viewer
/// - Annotations
/// - Document Editor
/// - Reader View
///
/// See https://www.nutrient.io/sdk/ios for the complete list of Nutrient iOS SDK’s features.

class EreaderExample: IndustryExample {

    var pdfController: PDFViewController!

    override init() {
        super.init()

        title = "E-Reader"
        contentDescription = "Shows how to configure Nutrient as an e-reader."
        category = .industryExamples
        targetDevice = [.vision, .phone, .pad]
        priority = 4
        wantsModalPresentation = true
        customizations = { container in
            container.modalPresentationStyle = .fullScreen
        }
        extendedDescription = "This example shows how to customize document viewing options to create an optimum user experience for reading research papers."
        url = URL(string: "https://www.nutrient.io/blog/industry-solution-ereader-ios/")!
        image = UIImage(systemName: "doc.richtext")
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
            // See https://www.nutrient.io/guides/ios/customizing-the-interface/document-presentation-options/ for more details.
            $0.pageTransition = .scrollContinuous
            $0.scrollDirection = .vertical

            // Miscellaneous configuration options.
            $0.isRenderAnimationEnabled = false
            $0.shouldHideNavigationBarWithUserInterface = false
            $0.shouldHideStatusBarWithUserInterface = false
        }

        super.init(document: document, configuration: configuration)

        // Customize the toolbar.
        // See https://www.nutrient.io/guides/ios/customizing-the-interface/customizing-the-toolbar/ for more details.
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)

        #if os(visionOS)
        setMainToolbarOrnamentItems([backOrnamentItem, moreInfo.barOrnamentItem, titleOrnamentItem, readerViewOrnamentItem, annotationToolsOrnamentItem, shareOrnamentItem, outlineOrnamentItem, searchOrnamentItem, thumbnailsOrnamentItem], for: .document)
        #else
        navigationItem.setLeftBarButtonItems([moreInfo.barButton, brightnessButtonItem, readerViewButtonItem], for: .document, animated: false)
        setUpdateSettingsForBoundsChange { [weak self] _ in
            self?.updateBarButtonItems()
        }
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBarButtonItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

    // MARK: Customization

    private func updateBarButtonItems() {
        let availableWidth = view.bounds.inset(by: view.safeAreaInsets).width

        // Show more items on wide screens. 430 is the minimum width needed to show 9 items including the close button.
        if availableWidth > 430 {
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, searchButtonItem, outlineButtonItem, activityButtonItem, annotationButtonItem], for: .document, animated: false)
        } else {
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, annotationButtonItem], for: .document, animated: false)
        }
    }
}
