//
//  Copyright © 2019-2024 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
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
        contentDescription = "Shows how to show a PDFViewController in SwiftUI with custom bar buttons."
        category = .swiftUI
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let swiftUIView = SwiftUICustomNavigationBarExampleView(document: document)
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

private struct SwiftUICustomNavigationBarExampleView: View {
    let document: Document

    // Publisher to trigger various events provided by the PDFView.
    private let actionEventPublisher = PassthroughSubject<PDFView.ActionEvent, Never>()
    @State private var viewMode = ViewMode.document
    @State private var showAnnotationToolbar = false

    var body: some View {
        return VStack {

            PDFView(document: document, viewMode: $viewMode, actionEventPublisher: actionEventPublisher)
                .scrollDirection(.vertical)
                .pageTransition(.scrollContinuous)
                .pageMode(.single)
                .spreadFitting(.fill)
                .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                .onWillBeginDisplayingPageView { _, pageIndex in print("Displaying page \(pageIndex)") }
                .navigationBarTitle(Text("Custom NavigationBar Example"))
                .navigationBarItems(trailing:
                                        HStack {
                                            barButton("pencil.and.outline") { _ in
                                                showAnnotationToolbar = !showAnnotationToolbar
                                                return .setAnnotationMode(showAnnotationMode: showAnnotationToolbar)
                                            }
                                            barButton("magnifyingglass") { .search(sender: $0) }
                                            barButton("book") { .showOutline(sender: $0) }

                                            if viewMode == .document {
                                                barButton("square.grid.2x2") { _ in
                                                    viewMode = .thumbnails
                                                    return nil
                                                }
                                            } else {
                                                barButton("square.grid.2x2.fill") { _ in
                                                    showAnnotationToolbar = false
                                                    viewMode = .document
                                                    return nil
                                                }
                                            }
                                        }
                )
        }
        // Prevent jumping of the content as we show/hide the navigation bar
        .edgesIgnoringSafeArea(.all)
    }

    // Helper to generate consistent buttons for the navigation bar.
    @MainActor private func barButton(_ systemImage: String, event: @escaping (AnyObject?) -> PDFView.ActionEvent?) -> some View {
        AnchorButton {
            if let realizedEvent = event($0) {
                actionEventPublisher.send(realizedEvent)
            }
        } content: {
            Image(systemName: systemImage)
                .padding(10) // padding increases the touch target
        }
    }

}

// MARK: Previews

struct SwiftUICustomNavigationBarExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .quickStart)
        SwiftUICustomNavigationBarExampleView(document: document)
    }
}
