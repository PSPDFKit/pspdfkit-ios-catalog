//
//  Copyright © 2024-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
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
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let swiftUIView = SwiftUIDefaultToolbarExampleView(document: document)
        let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        hostingController.modalPresentationStyle = .fullScreen

        return hostingController
    }
}

private struct SwiftUIDefaultToolbarExampleView: View {
    let document: Document
    @PDFView.Scope private var scope
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
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
    }
}

// MARK: Previews

struct SwiftUIMainToolbarExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .welcome)
        SwiftUIDefaultToolbarExampleView(document: document)
    }
}
