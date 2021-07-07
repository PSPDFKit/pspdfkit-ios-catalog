//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class SimpleAnnotationInspectorExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Simple Annotation Inspector"
        contentDescription = "Shows how to hide certain properties from the annotation inspector."
        category = .viewCustomization
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let pdfController = PDFViewController(document: document) {
            // Overrides the inspector with our own subclass to dynamically modify what properties we want to show.
            $0.overrideClass(AnnotationStyleViewController.self, with: SimpleAnnotationStyleViewController.self)
        }

        //  We use the delegate to customize the menu items.
        pdfController.delegate = self

        return pdfController
    }

    // MARK: - PDFViewControllerDelegate

    // Limit the menu options for selected highlight annotations, as they don't use the annotation inspector.
    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, for annotations: [Annotation]?, in annotationRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        // Only allow the remove, opacity, and color menus.
        return menuItems.filter {
            $0.identifier == TextMenu.annotationMenuRemove.rawValue ||
            $0.identifier == TextMenu.annotationMenuOpacity.rawValue ||
            $0.identifier?.hasPrefix(TextMenu.annotationMenuColor.rawValue) ?? false
        }
    }

    // Limit the menu options when text is selected.
    func pdfViewController(_ pdfController: PDFViewController, shouldShow menuItems: [MenuItem], atSuggestedTargetRect rect: CGRect, forSelectedText selectedText: String, in textRect: CGRect, on pageView: PDFPageView) -> [MenuItem] {
        // Only allow the copy, define, and highlight menus.
        return menuItems.filter {
            [TextMenu.copy, .define, .annotationMenuHighlight].map(\.rawValue).contains($0.identifier!)
        }
    }
}

private class SimpleAnnotationStyleViewController: AnnotationStyleViewController {

    override func properties(for annotations: [Annotation]) -> [[AnnotationStyle.Key]] {
        // Allow only a smaller list of known properties in the inspector popover.
        let supportedKeys: [AnnotationStyle.Key] = [.color, .alpha, .lineWidth, .fontSize]
        return super.properties(for: annotations).map {
            $0.filter { supportedKeys.contains($0) }
        }
    }
}
