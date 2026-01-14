//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

/// Example that shows how to use the Nutrient On-Device AI Assistant.
///
/// On-device AI Assistant runs entirely on the user’s Apple Intelligence-enabled device using Apple’s Foundation Models.
/// It does not require or communicate with the AI Assistant demo server.
/// See our [On-device AI Assistant guide](https://www.nutrient.io/guides/ios/ai-assistant/on-device/) for setup details.
class OnDeviceAIAssistantExample: Example {
    override init() {
        super.init()

        title = "On-Device AI Assistant"
        contentDescription = "AI chat for intelligent document analysis and interaction that keeps processing on the user’s device."
        category = .top
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        guard #available(iOS 26.0, *) else {
            delegate.currentViewController?.showAlert(
                withTitle: "Requires iOS 26",
                message: "On-device AI Assistant is available on Apple Intelligence-enabled devices running iOS 26 or later."
            )
            return nil
        }

        let document = AssetLoader.document(for: "Resource Depletion.pdf")

        let swiftUIView = OnDeviceAIAssistantExampleView(document: document)
        let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)

        return hostingController
    }
}

private struct OnDeviceAIAssistantExampleView: View {
    let document: Document
    @PDFView.Scope private var scope
    @State private var showingInfoSheet = false

    private let infoMessage = "On-device AI Assistant keeps processing on Apple Intelligence-enabled devices running iOS 26 or later.\nEnsure your license includes the on-device AI Assistant feature and that Apple Intelligence is enabled in Settings."
    private let guideURL = URL(string: "https://www.nutrient.io/guides/ios/ai-assistant/on-device/")!

    var body: some View {
        PDFView(document: document)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AIAssistantButton()
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingInfoSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("More Information")
                }
            }
            .alert("On-Device AI Assistant", isPresented: $showingInfoSheet) {
                Button("Copy on-device guide URL") {
                    UIPasteboard.general.url = guideURL
                }
                Button("Dismiss", role: .cancel) { }
            } message: {
                Text(infoMessage)
            }
            .pdfViewScope(scope)
    }
}
