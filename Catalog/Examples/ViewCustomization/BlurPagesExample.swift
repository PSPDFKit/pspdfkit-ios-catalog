//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class BlurPagesExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Blur Pages"
        contentDescription = "Shows how to blur specific pages in a document."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let controller = PDFViewController(document: document, delegate: self) {
            $0.pageTransition = .scrollPerSpread
            $0.pageMode = .single
            $0.thumbnailBarMode = .none
            $0.isTextSelectionEnabled = false
        }

        // Remove the thumbnails button item from the toolbar.
        let rightBarButtonItems = controller.navigationItem.rightBarButtonItems?.filter({ buttonItem -> Bool in
            return buttonItem != controller.thumbnailsButtonItem
        })
        controller.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: false)
        return controller
    }

    internal func pdfViewController(_ pdfController: PDFViewController, willBeginDisplaying pageView: PDFPageView, forPageAt pageIndex: Int) {
        // Only blur the first three pages.
        if pageIndex < 2 {
            // Blur pages if they aren't already blurred.
            if !pageView.isBlurred {
                let effect = UIBlurEffect(style: .light)
                let visualEffectView = UIVisualEffectView(effect: effect)
                visualEffectView.frame = pageView.bounds
                visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                pageView.addSubview(visualEffectView)
            }
        } else {
            // Remove the visual effect view from the blurred pages if necessary.
            for view in pageView.subviews where view is UIVisualEffectView {
                view.removeFromSuperview()
            }
        }
    }
}

fileprivate extension PDFPageView {
    var isBlurred: Bool {
        return self.subviews.contains(where: { $0 is UIVisualEffectView })
    }
}
