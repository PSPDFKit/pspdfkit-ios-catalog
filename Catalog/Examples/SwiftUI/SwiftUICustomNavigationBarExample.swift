//
//  Copyright © 2019-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Combine
import PSPDFKit
import PSPDFKitUI
import SwiftUI

class SwiftUICustomNavigationBarExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Custom NavigationBar Example"
        contentDescription = "Shows how to show a PDFView in SwiftUI with custom bar buttons."
        category = .swiftUI
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let swiftUIView = SwiftUICustomNavigationBarExampleView(document: document)
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

private struct SwiftUICustomNavigationBarExampleView: View {
    let document: Document

    @State private var viewMode = ViewMode.document
    @PDFView.Scope private var scope

    var body: some View {
        PDFView(document: document, viewMode: $viewMode)
            .scrollDirection(.vertical)
            .pageTransition(.scrollContinuous)
            .pageMode(.single)
            .spreadFitting(.adaptive)
            .onWillBeginDisplayingPageView { _, pageIndex in print("Displaying page \(pageIndex)") }
            .navigationTitle(Text("Custom NavigationBar Example"))
            .toolbar {
                // Add the default toolbar items.
                DefaultToolbarButtons(for: [.thumbnails])

                // Setup buttons to be shown in the document view mode.
                ToolbarItemGroup {
                    if viewMode == .document {
                        // Add custAnnotation button with a custom label that toggles the annotation toolbar.
                        AnnotationButton {
                            Image(systemName: "pencil.and.outline")
                        }
                        SearchButton()
                        OutlineButton()
                        ThumbnailsButton()
                    }
                }
            }
            // Set the scope for the view hierarchy so the default toolbar buttons and the PDFView can communicate.
            .pdfViewScope(scope)
    }
}

// MARK: Previews

struct SwiftUICustomNavigationBarExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .welcome)
        SwiftUICustomNavigationBarExampleView(document: document)
    }
}
