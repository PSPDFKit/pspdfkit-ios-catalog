//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import os
import SwiftUI
import Combine
import PSPDFKitUI

@available(iOS 14.0, *)
private let logger = Logger(subsystem: "com.pspdfkit.catalog", category: "swiftui-toolbar-example")

class SwiftUIAnnotationToolbarExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Custom Annotation Toolbar Example"
        contentDescription = "Shows how to show a custom annotation toolbar in SwiftUI."
        category = .swiftUI
        priority = 11

        // Do not show the example in the list if running on iOS 12/13.
        // Implementation note: This example uses modern toolbar and image API.
        // With some additional work, iOS 13 can be supported.
        if #available(iOS 14, *) {} else {
            targetDevice = []
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        if #available(iOS 14, *) {
            let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
            let swiftUIView = SwiftUIAnnotationToolbarExampleView(document: document)
            return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        }
        return nil
    }
}

/// The store that bridges the annotation mode to the PDFViewController.
@available(iOS 14.0, *)
final class SwiftUIAnnotationToolbarStore: ObservableObject {
    var stateKVO: AnyCancellable?
    let actionEventPublisher = PassthroughSubject<PDFView.ActionEvent, Never>()

    @Published var viewMode = ViewMode.document {
        didSet {
            // Hide toolbar when showing thumbnails.
            if !isShowingDocument {
                showAnnotationToolbar = false
            }
        }
    }

    @Published var showAnnotationToolbar = false {
        didSet {
            // Disable annotation mode if toolbar disappears
            if !showAnnotationToolbar {
                annotationMode = nil
            }
        }
    }

    @Published var annotationMode: Annotation.Tool? {
        didSet {
            annotationStateManager?.state = annotationMode
            logger.info("New State: \(self.annotationMode?.rawValue ?? "(none)")")
        }
    }

    /// View mode is set to show the document.
    var isShowingDocument: Bool {
        viewMode == .document
    }

    /// Toggle view mode between document and thumbnails.
    func toggleViewMode() {
        actionEventPublisher.send(.setViewMode(viewMode: isShowingDocument ? .thumbnails : .document, animated: true))
    }

    // Connected from the PSPDFVC
    var annotationStateManager: AnnotationStateManager? {
        didSet {
            // Add KVO to forward state changes.
            // Implementation note: More complex versions might also need `variant` to capture the full state.
            guard let manager = annotationStateManager else { return }
            stateKVO = manager.publisher(for: \.state).sink { [weak self] newValue in
                guard let self = self else { return }

                if self.annotationMode != newValue {
                    self.annotationMode = newValue
                }
            }
        }
    }
}

/// The main view for this example.
@available(iOS 14.0, *)
private struct SwiftUIAnnotationToolbarExampleView: View {
    @ObservedObject var store = SwiftUIAnnotationToolbarStore()
    @ObservedObject var document: Document

    var body: some View {
        ZStack {
            PDFView(document: _document, viewMode: $store.viewMode, actionEventPublisher: store.actionEventPublisher)
                .scrollDirection(.vertical)
                .pageTransition(.scrollContinuous)
                .pageMode(.single)
                .spreadFitting(.fill)
                .updateControllerConfiguration {
                    // Connect the state manager with the store to manage state.
                    if store.annotationStateManager != $0.annotationStateManager {
                        store.annotationStateManager = $0.annotationStateManager
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            logger.info("Toggle Annotation Toolbar")
                            store.showAnnotationToolbar.toggle()
                        }) {
                            Label("Toggle Annotation Toolbar", systemImage: "scribble")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            logger.info("Toggle View Mode")
                            store.toggleViewMode()
                        }) {
                            Label("Toggle View Mode", systemImage: "square.grid.2x2")
                        }
                    }
                }

            // The custom toolbar is added above the PDFView via the ZStack.
            CustomAnnotationToolbarView(store: store)
        }
    }
}

@available(iOS 14.0, *)
private struct CustomAnnotationToolbarView: View {
    @ObservedObject var store: SwiftUIAnnotationToolbarStore

    var body: some View {
        HStack {
            Spacer()
            VStack {
                ToolbarViewButton(store: store,
                                  annotationMode: .highlight,
                                  title: "Highlighter",
                                  imageName: "highlighter")
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))

                ToolbarViewButton(store: store,
                                  annotationMode: .ink,
                                  title: "Drawing",
                                  imageName: "pencil")

                ToolbarViewButton(store: store,
                                  annotationMode: .freeText,
                                  title: "Text",
                                  imageName: "text.cursor")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
            }
            .frame(width: 50)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                        .opacity(0.8))
            .shadow(color: Color.black.opacity(0.2), radius: 4)
            .padding(20)
            .opacity(store.showAnnotationToolbar ? 1 : 0)
            .scaleEffect(store.showAnnotationToolbar ? 1 : 0.8)
            .animation(.easeInOut)
        }.frame(maxWidth: .infinity)
    }
}

@available(iOS 14.0, *)
extension CustomAnnotationToolbarView {
    private struct ToolbarViewButton: View {
        @ObservedObject var store: SwiftUIAnnotationToolbarStore
        @Environment(\.colorScheme) var colorScheme

        var annotationMode: Annotation.Tool
        var title: String
        var imageName: String

        var isActive: Bool {
            store.annotationMode == annotationMode
        }

        var body: some View {
            Button(action: {
                logger.info("\(title) tapped, toggling \(annotationMode)")
                store.annotationMode = isActive ? nil : annotationMode
            }) {
                Label(title, systemImage: imageName)
                    .labelStyle(IconOnlyLabelStyle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(10)
            .background(isActive ? Color.blue : Color.clear)
            .foregroundColor(isActive ? .white : colorScheme == .light ? .black : .white)
            .cornerRadius(5)
            .padding(5)
        }
    }
}

// MARK: Previews

@available(iOS 14.0, *)
struct SwiftUIAnnotationToolbarExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .quickStart)
        SwiftUIAnnotationToolbarExampleView(document: document)
    }
}
