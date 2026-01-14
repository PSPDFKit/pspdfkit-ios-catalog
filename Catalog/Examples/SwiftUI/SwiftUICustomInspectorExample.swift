//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

/// This example demonstrates a way to load parts of a document on demand in SwiftUI.
class SwiftUICustomInspectorExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Custom Annotation Inspector Example"
        contentDescription = "Presents a custom SwiftUI-based Inspector written in SwiftUI."
        category = .swiftUI
        priority = 21
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let swiftUIView = SwiftUICustomInspectorExampleView(document: document)
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

// Coordinator that handles custom inspector presentation.
@MainActor private class CustomInspectorPresentationManager: ObservableObject {
    weak var pdfController: PDFViewController?

    func presentInspector(from rect: CGRect, animated: Bool) {
        guard let pdfController else { return }

        // Build SwiftUI custom Inspector and pass on selected annotations.
        let inspector = CustomInspectorView(annotations: pdfController.selectedAnnotations)

        // Prepare UIKit hosting container
        let inspectorController = UIHostingController(rootView: inspector, largeTitleDisplayMode: .never)
        inspectorController.modalPresentationStyle = .popover
        inspectorController.popoverPresentationController?.sourceRect = rect
        inspectorController.popoverPresentationController?.sourceView = pdfController.view

        // Manually set preferredContentSize for the popover
        let popoverMaxSize = CGSize(width: 250, height: 500)
        inspectorController.preferredContentSize = inspectorController.sizeThatFits(in: popoverMaxSize)

        // Finally, present it
        pdfController.present(inspectorController, animated: animated)
    }
}

private struct SwiftUICustomInspectorExampleView: View {
    let document: Document
    @StateObject var inspectorPresentationManager = CustomInspectorPresentationManager()
    @PDFView.Scope private var scope

    var body: some View {
        PDFView(document: document)
            .scrollDirection(.vertical)
            .pageTransition(.scrollContinuous)
            .pageMode(.single)
            .spreadFitting(.adaptive)
            .userInterfaceViewMode(.always)
            .updateControllerConfiguration { pdfController in
                // We need a reference of the PDFController in our custom presentation manager
                inspectorPresentationManager.pdfController = pdfController
            }
            .onShouldShowController { controller, options, animated in
                // If the SDK is about to present the annotation style view controller; present manually.
                guard controller is AnnotationStyleViewController,
                      let sourceRect = options?[PresentationOption.sourceRect.rawValue] as? CGRect else { return true }

                // Call logic to present custom inspector and indicate that custom logic takes over (via returning false)
                inspectorPresentationManager.presentInspector(from: sourceRect, animated: animated)
                return false
            }
            .showDocumentTitle()
            .toolbar {
                DefaultToolbarButtons()
            }
            .pdfViewScope(scope)
    }
}

private struct CustomInspectorView: View {
    var annotations: [Annotation]

    // Helper to modify annotations color
    private func changeAnnotationsColor(to color: UIColor) {
        annotations.forEach { annotation in
            annotation.color = color

            // Important: If we change annotation properties, post a change notification to update UI.
            // https://www.nutrient.io/guides/ios/annotations/the-annotation-object-model/
            NotificationCenter.default.post(name: .PSPDFAnnotationChanged,
                                            object: annotation,
                                            userInfo: [PSPDFAnnotationChangedNotificationKeyPathKey: ["color"]])
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Button("Make Yellow") { changeAnnotationsColor(to: .yellow) }
                Button("Make Green") { changeAnnotationsColor(to: .green) }
                Button("Make Blue") { changeAnnotationsColor(to: .blue) }
            }
            .navigationBarTitle("Inspector", displayMode: .inline)
        }
        .frame(width: 300, height: 300, alignment: .topTrailing)
    }
}
