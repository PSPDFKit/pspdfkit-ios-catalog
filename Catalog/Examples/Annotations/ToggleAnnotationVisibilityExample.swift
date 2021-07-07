//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class ToggleAnnotationVisibilityExample: Example {

    override init() {
        super.init()
        title = "Toggle Annotation Visibility"
        contentDescription = "Allow users to hide or show annotations."
        type = "com.pspdfkit.catalog.playground.swift"
        category = .annotations
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        // Clear cache before presenting the view controller so that pages are
        // re-rendered with annotations visible by default, in case the last
        // cache has annotations hidden.
        PSPDFKit.SDK.shared.cache.remove(for: document)
        // Due to the limitation of this example, thumbnail bar won't be updated
        // when hiding or showing annotations. So let's disable it.
        let controller = ToggleAnnotationVisibilityViewController(document: document) { builder in
            builder.thumbnailBarMode = .none
        }
        // Go directly to the page with annotations.
        controller.pageIndex = 15
        return controller
    }
}

private class ToggleAnnotationVisibilityViewController: PDFViewController {

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        let toggleAnnotationVisibilityBarButtonItem = UIBarButtonItem(image: UIImage(namedInCatalog: "hide"), style: .plain, target: self, action: #selector(didTapToggleAnnotationVisibilityBarButtonItem))
        toggleAnnotationVisibilityBarButtonItem.title = "hide"
        navigationItem.rightBarButtonItems = [toggleAnnotationVisibilityBarButtonItem]
    }

    @objc func didTapToggleAnnotationVisibilityBarButtonItem(_ sender: UIBarButtonItem) {
        // Let link annotations be always visible.
        if sender.title == "hide" {
            setVisibleAnnotationTypes(.link)
            sender.title = "show"
            sender.image = UIImage(namedInCatalog: "show")
        } else {
            setVisibleAnnotationTypes(.all)
            sender.title = "hide"
            sender.image = UIImage(namedInCatalog: "hide")
        }
    }

    // MARK: Private

    private func setVisibleAnnotationTypes(_ types: Annotation.Kind) {
        // Update the render types.
        document?.renderAnnotationTypes = types
        // Clear the cache so that pages are re-rendered once updated.
        PSPDFKit.SDK.shared.cache.remove(for: document)
        for pageView in visiblePageViews {
            pageView.updateAnnotationViews(animated: false)
            pageView.update()
        }
    }
}
