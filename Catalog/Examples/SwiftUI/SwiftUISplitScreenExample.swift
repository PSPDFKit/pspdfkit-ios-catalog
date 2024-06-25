//
//  Copyright © 2019-2024 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

class SwiftUISplitScreenExample: Example {

    override init() {
        super.init()

        title = "SwiftUI SplitScreen Example"
        contentDescription = "Shows how to show two PDFViewController in SwiftUI side by side."
        category = .swiftUI
        priority = 13
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let leadingDocument = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
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

    var body: some View {
        HStack(spacing: 0) {
            // First view uses continuous vertical scrolling.
            NavigationView {
                PDFView(document: leadingDocument)
                    .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                    .scrollDirection(.vertical)
                    .pageTransition(.scrollContinuous)
                    .pageMode(.single)
                    .spreadFitting(.fill)
                    .userInterfaceViewMode(.always)
                    .navigationTitle(LocalizedStringKey(leadingDocument.title!))
                    .navigationBarTitleDisplayMode(.inline)

            }.navigationViewStyle(StackNavigationViewStyle())

            Divider()

            // Second view uses horizontal per-page scrolling.
            NavigationView {
                PDFView(document: trailingDocument)
                    .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                    .scrollDirection(.horizontal)
                    .pageTransition(.scrollPerSpread)
                    .pageMode(.single)
                    .spreadFitting(.fill)
                    .userInterfaceViewMode(.always)
                    .navigationTitle(LocalizedStringKey(trailingDocument.title!))
                    .navigationBarTitleDisplayMode(.inline)
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: Previews

struct SwiftUISplitScreenExamplePreviews: PreviewProvider {
    static var previews: some View {
        let leadingDocument = AssetLoader.document(for: .quickStart)
        let trailingDocument = AssetLoader.document(for: .annualReport)
        SwiftUISplitScreenExampleView(leadingDocument: leadingDocument, trailingDocument: trailingDocument)
    }
}
