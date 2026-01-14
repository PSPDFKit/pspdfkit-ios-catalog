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

private extension NSNotification.Name {
    static let DismissHostingController = NSNotification.Name("DismissHostingControllerNotification")
}

class SwiftUISidebarExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Sidebar Example"
        contentDescription = "Shows how to show a PDFView in SwiftUI with sidebar."
        category = .swiftUI
        priority = 10
        // We present this modal, as SwiftUI controls the navigation controller here.
        wantsModalPresentation = true
        embedModalInNavigationController = false
    }

    private var dismissSink: AnyCancellable?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .welcome)
        let swiftUIView = SwiftUISidebarExampleView(document: document)

        let hostingController = DismissableHostingViewController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen

        dismissSink = NotificationCenter.default.publisher(for: .DismissHostingController)
            .sink { _ in hostingController.dismiss(animated: true, completion: nil) }

        return hostingController
    }
}

final private class DismissableHostingViewController: UIHostingController<SwiftUISidebarExampleView> {
    override init(rootView: SwiftUISidebarExampleView) {
        super.init(rootView: rootView)
        self.rootView.dismiss = dismiss
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

private struct SwiftUISidebarExampleView: View {
    @ObservedObject var document: Document

    // Logic is connected from the hosting view controller.
    var dismiss: (() -> Void)?

    @State private var sidebarActionHandler = SidebarActionHandler(didSelectAnnotation: { _ in }, didSelectBookmark: { _ in }, didSelectOutline: { _ in })

    var body: some View {
        NavigationView {
            Sidebar(dismiss: dismiss!)
            CombinedSidebar(document: document, actionHandler: sidebarActionHandler) // aka "PrimaryView"
            DetailView(document: document, sidebarActionHandler: $sidebarActionHandler)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct Sidebar: View {
    let dismiss: (() -> Void)

    var body: some View {
        Button("Exit Example", action: dismiss)
    }
}

private struct DetailView: View {
    let document: Document
    @Binding var sidebarActionHandler: SidebarActionHandler
    private let actionEventPublisher = PassthroughSubject<PDFView.ActionEvent, Never>()
    @State private var selectedAnnotations: [Annotation] = []

    var body: some View {
        PDFView(document: document, selectedAnnotations: $selectedAnnotations, actionEventPublisher: actionEventPublisher) {
            $0.pageTransition = .scrollContinuous
            $0.scrollDirection = .vertical
            $0.pageMode = .single
            $0.spreadFitting = .adaptive
        }
        .onAppear {
            // connect the sidebar handler with the event publisher
            sidebarActionHandler = SidebarActionHandler { annotation in
                selectedAnnotations = [annotation]
            } didSelectBookmark: { bookmark in
                actionEventPublisher.send(.setPageIndex(index: bookmark.pageIndex))
            } didSelectOutline: { outlineElement in
                actionEventPublisher.send(.setPageIndex(index: outlineElement.pageIndex))
            }
        }
    }
}

// MARK: Previews

struct SwiftUISidebarExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .welcome)
        SwiftUISidebarExampleView(document: document)
    }
}
