//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class SelectAllTextExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()
        title = "Select All Text"
        contentDescription = "Shows how to add a “Select All” item to the menu."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        PDFViewController(document: AssetLoader.document(for: .JKHF), delegate: self)
    }

    private func selectAllMenuItem(for pageView: PDFPageView) -> MenuItem? {
        guard let allGlyphs = pageView.presentationContext?.document?.textParserForPage(at: pageView.pageIndex)?.glyphs, !allGlyphs.isEmpty else {
            return nil
        }
        // Make sure we haven't selected all text already.
        guard pageView.selectionView.selectedGlyphs.count != allGlyphs.count else {
            return nil
        }
        // Menu items are saved in a global object so it's recommended to not
        // retain strong references in their action blocks.
        return MenuItem(title: "Select All") { [weak pageView] in
            // We need to manually sort the glyphs.
            guard let pageView = pageView else { return }
            pageView.selectionView.selectedGlyphs = pageView.selectionView.sortedGlyphs(allGlyphs)
            // The menu is still visible inside this closure. To display a new
            // one after all text is selected, we need to delay the call.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pageView.showMenuIfSelected(animated: true)
            }
        }
    }

    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, forSelectedText selectedText: String, in textRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        if let selectAll = selectAllMenuItem(for: pageView) {
            return [selectAll] + menuItems
        } else {
            return menuItems
        }
    }

    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, for annotations: [Annotation]?, in annotationRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        // Show only in the annotation creation menu.
        if let selectAll = selectAllMenuItem(for: pageView), (annotations?.isEmpty ?? true) {
            return [selectAll] + menuItems
        } else {
            return menuItems
        }
    }

}
