//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI
import Combine

/// SwiftUI example demonstrating how to integrate AI Assistant with a single PDF document using AIAssistantView.
///
/// This example shows how to:
/// - Show AIAssistantView in SwiftUI in an inspector
/// - Handle document navigation when AI Assistant provides responses
#if !os(visionOS)
@available(iOS 17.0, *)
class SwiftUIAIAssistantExample: Example {
    override init() {
        super.init()

        title = "SwiftUI AI Assistant"
        contentDescription = "Demonstrates how the AI Assistant SwiftUI view can be used."
        category = .swiftUI
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        // Create AI Assistant configuration and session
        let configuration = createAIAssistantConfiguration(for: document)
        let session = AIAssistantSession(documents: [document], configuration: configuration)

        // Create the SwiftUI view
        let swiftUIView = SwiftUIAIAssistantExampleView(document: document, aiAssistantSession: session)
        let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)

        return hostingController
    }

    /// Creates AI Assistant configuration for a single document.
    private func createAIAssistantConfiguration(for document: Document) -> AIAssistantConfiguration {
        // When running this example on a device on a machine other than the machine running the AI Assistant demo server,
        // replace the server URL with the IP address of the machine running the demo server.
        let serverURL = URL(string: "http://localhost:4000")!

        let sessionID = "ios-swiftui-session-id"

        // Create JWT with the document ID that is hexadecimal-encoded
        // and add allowed session IDs for the user.
        let claims: [String: Any] = [
            "document_ids": [document.documentId!.hexadecimalEncodedString()],
            "session_ids": [sessionID],
        ]

        // We create the JWT on the client side with a private key.
        // The JWT should ideally not be created like this, as it is
        // not recommended to store private keys on the client.
        // It should be created on the server side and sent to the client.
        let jwt: String
        do {
            jwt = try AIAssistantExampleJWTSigner.createAndSignJWT(claims: claims)
        } catch {
            fatalError("Couldn't Set Up AI Assistant. Error creating JWT: \(error)")
        }

        return AIAssistantConfiguration(serverURL: serverURL, jwt: jwt, sessionID: sessionID)
    }
}

/// SwiftUI view that displays AI Assistant chat alongside a PDF document
@available(iOS 17.0, *)
private struct SwiftUIAIAssistantExampleView: View {
    let document: Document
    @ObservedObject var aiAssistantSession: AIAssistantSession

    @State private var showingAssistant = false

    // Action event publisher for triggering navigation in PDF view
    private let pdfActionEventPublisher = PassthroughSubject<PDFView.ActionEvent, Never>()

    var body: some View {
        PDFView(document: document, actionEventPublisher: pdfActionEventPublisher)
            .inspector(isPresented: $showingAssistant) {
                AIAssistantView(session: aiAssistantSession)
                    .onDocumentNavigationAction { _, pageIndex, rects in
                        // Navigate to the specified page with highlights
                        pdfActionEventPublisher.send(.setPageIndexWithHighlights(pageIndex, rects))
                    }
                    .navigationTitle("AI Assistant")
                    .presentationDetents([.large])
            }
            .toolbar {
                // Add AI Assistant toggle button as trailing toolbar item
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAssistant.toggle()
                    } label: {
                        Image(uiImage: SDK.imageNamed("ai")!)
                    }
                    .accessibilityLabel("Toggle AI Assistant")
                }
            }
    }
}
#endif
