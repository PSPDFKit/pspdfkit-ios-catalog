//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class SelectAllTextExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()
        title = "Select All Text"
        contentDescription = "Shows how to add a “Select All” item to the menu."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        PDFViewController(document: AssetLoader.document(for: .annualReport), delegate: self)
    }

    private func selectAllAction(for pageView: PDFPageView) -> UIAction? {
        // Make sure there is selectable text on page.
        guard let glyphs = pageView.presentationContext?.document?.textParserForPage(at: pageView.pageIndex)?.glyphs, !glyphs.isEmpty else {
            return nil
        }
        // Make sure we haven't selected all text already.
        guard pageView.selectionView.selectedGlyphs.count != glyphs.count else {
            return nil
        }
        return UIAction(title: "Select All", image: UIImage(systemName: "a.square.fill")) { _ in
            // We need to manually sort the glyphs.
            pageView.select(glyphs: glyphs, animated: true)
        }
    }

    func pdfViewController(_ sender: PDFViewController, menuForCreatingAnnotationAt point: CGPoint, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        if let action = selectAllAction(for: pageView) {
            return suggestedMenu.prepend([action])
        } else {
            return suggestedMenu
        }
    }

}
