//
//  Copyright © 2024 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

class SwiftUIDefaultToolbarExample: Example {

    override init() {
        super.init()

        title = "Default main toolbar buttons in SwiftUI "
        contentDescription = "Shows how to show add the default buttons to the main toolbar of the PDFView in SwiftUI."
        category = .swiftUI
        wantsModalPresentation = true
        embedModalInNavigationController = false
        priority = 11
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let swiftUIView = SwiftUIDefaultToolbarExampleView(document: document)
        let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        hostingController.modalPresentationStyle = .fullScreen

        if #unavailable(iOS 16) {
            // Use UIAppearance API to set the navigation bar appearance on iOS 15.
            let navigationBar = UINavigationBar.appearance(whenContainedInInstancesOf: [UIHostingController<SwiftUIDefaultToolbarExampleView>.self])
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        }

        return hostingController
    }
}

private struct SwiftUIDefaultToolbarExampleView: View {
    let document: Document
    @PDFView.Scope var scope
    @Environment(\.dismiss) var dismiss

    @ViewBuilder private var pdfView: some View {
        PDFView(document: document)
            .toolbar {
                // Add the default toolbar items.
                DefaultToolbarButtons()
                // Add Done button to dismiss example as a custom toolbar item.
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Done")
                    })
                }
            }
            // Set the scope for the view hierarchy so the default toolbar buttons and the PDFView can communicate.
            .pdfViewScope(scope)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                pdfView
            }
        } else {
            NavigationView {
                pdfView
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationViewStyle(.stack)
        }
    }
}

// MARK: Previews

struct SwiftUIMainToolbarExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .quickStart)
        SwiftUIDefaultToolbarExampleView(document: document)
    }
}
