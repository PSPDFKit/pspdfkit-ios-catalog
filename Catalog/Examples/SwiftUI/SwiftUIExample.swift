//
//  Copyright © 2019-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

class SwiftUIExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Example"
        contentDescription = "Shows how to show a PDFViewController in SwiftUI."
        category = .swiftUI
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let swiftUIView = SwiftUIExampleView(document: document)
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

private struct SwiftUIExampleView: View {
    let document: Document
    @PDFView.Scope private var scope

    var body: some View {
        PDFView(document: document)
            .scrollDirection(.vertical)
            .pageTransition(.scrollContinuous)
            .pageMode(.single)
            .spreadFitting(.adaptive)
            // Enable displaying the document title.
            .showDocumentTitle()
            // Add PDFView buttons to the toolbar.
            .toolbar {
                ReaderViewButton()
                AnnotationButton()
                ThumbnailsButton()
            }
            .pdfViewScope(scope)
    }
}

// MARK: Previews

struct SwiftUIExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .welcome)
        SwiftUIExampleView(document: document)
    }
}
