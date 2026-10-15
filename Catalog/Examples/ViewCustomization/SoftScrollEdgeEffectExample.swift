//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// Shows how to use the soft scroll edge effect for the document scroll view.
///
/// Nutrient doesn’t set a scroll edge effect style of its own and follows the system default, so
/// the appearance changes with the OS version. iOS 27 defaults to the hard edge effect, which fades
/// the content below the navigation bar with a clear cutoff and a dividing line. iOS 26 defaulted to
/// the soft edge effect, which fades out the content more gradually and without a dividing line.
/// Apps that prefer the softer look can opt into it by setting the style of the document scroll
/// view’s edge effects.
class SoftScrollEdgeEffectExample: Example, PDFDocumentViewControllerDelegate {

    override init() {
        super.init()

        title = "Soft Scroll Edge Effect"
        contentDescription = "Uses the soft scroll edge effect instead of the hard edge effect that iOS 27 uses by default."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        guard #available(iOS 26.0, visionOS 26.0, *) else {
            delegate.currentViewController?.showAlert(withTitle: "Requires iOS 26", message: "Scroll edge effects are only available on iOS 26 and later.")
            return nil
        }

        let document = AssetLoader.document(for: .magazine)
        let controller = PDFViewController(document: document) {
            // Continuous scrolling makes the edge effect easy to spot because the page content
            // keeps moving below the navigation bar while scrolling.
            $0.pageTransition = .scrollContinuous
            $0.scrollDirection = .vertical
            $0.pageMode = .single
        }
        controller.documentViewController?.delegate = self
        return controller
    }

    // MARK: PDFDocumentViewControllerDelegate

    // This is the scroll view that scrolls the spreads, so its edge effects are the ones shown
    // below the navigation bar and above the thumbnail bar.
    func documentViewController(_ documentViewController: PDFDocumentViewController, configureScrollView scrollView: UIScrollView) {
        guard #available(iOS 26.0, visionOS 26.0, *) else { return }

        scrollView.topEdgeEffect.style = .soft
        scrollView.bottomEdgeEffect.style = .soft
    }
}
