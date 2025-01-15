//
//  Copyright © 2019-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

class SwiftUISplitScreenExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Split-Screen Example"
        contentDescription = "Shows how to show two PDFViews in SwiftUI side by side."
        category = .swiftUI
        priority = 13
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let leadingDocument = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let trailingDocument = AssetLoader.writableDocument(for: .annualReport, overrideIfExists: false)
        let swiftUIView = SwiftUISplitScreenExampleView(leadingDocument: leadingDocument, trailingDocument: trailingDocument)
        let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        hostingController.title = "SwiftUI SplitScreen Example"

        return hostingController
    }
}

private struct SwiftUISplitScreenExampleView: View {
    let leadingDocument: Document
    let trailingDocument: Document
    @PDFView.Scope private var leadingViewScope
    @PDFView.Scope private var trailingViewScope

    var body: some View {
        HStack(spacing: 0) {
            // First view uses continuous vertical scrolling.
            NavigationView {
                PDFView(document: leadingDocument)
                    .scrollDirection(.vertical)
                    .pageTransition(.scrollContinuous)
                    .pageMode(.single)
                    .spreadFitting(.adaptive)
                    .userInterfaceViewMode(.always)
                    .toolbar {
                        // Add the default toolbar items.
                        DefaultToolbarButtons()
                    }
                    .pdfViewScope(leadingViewScope)
                    .navigationTitle(LocalizedStringKey(leadingDocument.title!))
                    .navigationBarTitleDisplayMode(.inline)
            }.navigationViewStyle(StackNavigationViewStyle())

            Divider()

            // Second view uses horizontal per-page scrolling.
            NavigationView {
                PDFView(document: trailingDocument)
                    .scrollDirection(.horizontal)
                    .pageTransition(.scrollPerSpread)
                    .pageMode(.single)
                    .spreadFitting(.fill)
                    .userInterfaceViewMode(.always)
                    .toolbar {
                        // Add the default toolbar items.
                        DefaultToolbarButtons()
                    }
                    .pdfViewScope(trailingViewScope)
                    .navigationTitle(LocalizedStringKey(trailingDocument.title!))
                    .navigationBarTitleDisplayMode(.inline)
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: Previews

struct SwiftUISplitScreenExamplePreviews: PreviewProvider {
    static var previews: some View {
        let leadingDocument = AssetLoader.document(for: .welcome)
        let trailingDocument = AssetLoader.document(for: .annualReport)
        SwiftUISplitScreenExampleView(leadingDocument: leadingDocument, trailingDocument: trailingDocument)
    }
}
