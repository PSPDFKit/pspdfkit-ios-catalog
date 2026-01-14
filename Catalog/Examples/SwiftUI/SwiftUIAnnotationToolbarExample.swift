//
//  Copyright © 2019-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Combine
import os
import PSPDFKit
import PSPDFKitUI
import SwiftUI

private let logger = Logger(subsystem: "com.pspdfkit.catalog", category: "swiftui-toolbar-example")

class SwiftUIAnnotationToolbarExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Custom Annotation Toolbar Example"
        contentDescription = "Shows how to show a custom annotation toolbar in SwiftUI."
        category = .swiftUI
        priority = 11
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let swiftUIView = SwiftUIAnnotationToolbarExampleView(document: document)
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

/// The store that bridges the annotation mode to the PDFViewController.
@MainActor final class SwiftUIAnnotationToolbarStore: ObservableObject {
    @MainActor final class AnnotationModeStore: ObservableObject {
        var stateKVO: AnyCancellable?

        @Published var annotationMode: Annotation.Tool? {
            didSet {
                annotationStateManager?.state = annotationMode
                logger.info("New State: \(self.annotationMode?.rawValue ?? "(none)")")
            }
        }

        // Connected from the PSPDFVC
        var annotationStateManager: AnnotationStateManager? {
            didSet {
                // Add KVO to forward state changes.
                // Implementation note: More complex versions might also need `variant` to capture the full state.
                guard let manager = annotationStateManager else { return }
                stateKVO = manager.publisher(for: \.state).sink { [weak self] newValue in
                    guard let self else { return }

                    if self.annotationMode != newValue {
                        self.annotationMode = newValue
                    }
                }
            }
        }
    }
    let annotationModeStore = AnnotationModeStore()

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
                annotationModeStore.annotationMode = nil
            }
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
}

/// The main view for this example.
private struct SwiftUIAnnotationToolbarExampleView: View {
    @ObservedObject var store = SwiftUIAnnotationToolbarStore()
    let document: Document

    var body: some View {
        ZStack {
            PDFView(document: document, viewMode: $store.viewMode, actionEventPublisher: store.actionEventPublisher)
                .scrollDirection(.vertical)
                .pageTransition(.scrollContinuous)
                .pageMode(.single)
                .spreadFitting(.adaptive)
                .updateControllerConfiguration {
                    // Connect the state manager with the store to manage state.
                    if store.annotationModeStore.annotationStateManager != $0.annotationStateManager {
                        store.annotationModeStore.annotationStateManager = $0.annotationStateManager
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

private struct CustomAnnotationToolbarView: View {
    @ObservedObject var store: SwiftUIAnnotationToolbarStore

    var body: some View {
        HStack {
            Spacer()
            VStack {
                ToolbarViewButton(store: store.annotationModeStore,
                                  annotationMode: .highlight,
                                  title: "Highlighter",
                                  imageName: "highlighter")
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))

                ToolbarViewButton(store: store.annotationModeStore,
                                  annotationMode: .ink,
                                  title: "Drawing",
                                  imageName: "pencil")

                ToolbarViewButton(store: store.annotationModeStore,
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
            .animation(.easeInOut, value: store.showAnnotationToolbar)
            .animation(.easeInOut, value: store.annotationModeStore.annotationMode)
        }.frame(maxWidth: .infinity)
    }
}

extension CustomAnnotationToolbarView {
    private struct ToolbarViewButton: View {
        @ObservedObject var store: SwiftUIAnnotationToolbarStore.AnnotationModeStore
        @Environment(\.colorScheme) var colorScheme

        let annotationMode: Annotation.Tool
        let title: String
        let imageName: String

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

struct SwiftUIAnnotationToolbarExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(for: .welcome)
        SwiftUIAnnotationToolbarExampleView(document: document)
    }
}
