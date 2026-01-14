//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

/// Example demonstrating how to integrate AI Assistant with multiple PDF documents.
///
/// This example shows how to:
/// - Set up AIAssistantViewController with multiple documents
/// - Configure JWT tokens with multiple document IDs for server authentication
/// - Use ModalSidebarSplitViewController for adaptive presentation of the sidebar in a modal
/// - Navigate between documents when AI Assistant provides document-specific responses
///
/// Key integration points:
/// 1. Create AIAssistantConfiguration with JWT containing all document IDs
/// 2. Pass all documents to AIAssistantViewController
/// 3. Implement the AIAssistantViewControllerDelegate for handling navigation to links tapped in the AI Assistant.
/// 4. Use ModalSidebarSplitViewController for presentation management
///
/// Please reach out to us on support (https://www.nutrient.io/support/request) if you have any questions about the API.
class MultiDocumentAIAssistantExample: Example {
    override init() {
        super.init()

        title = "AI Assistant with multiple documents"
        contentDescription = "Demonstrates how the AI Assistant can be presented individually for use with multiple documents."
        category = .top
        priority = 30
        wantsModalPresentation = true
        embedModalInNavigationController = false
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let documents: [Document] = [
            AssetLoader.writableDocument(for: .welcome, overrideIfExists: false),
            AssetLoader.writableDocument(for: .psychologyResearch, overrideIfExists: false),
            AssetLoader.writableDocument(for: "Resource Depletion.pdf", overrideIfExists: false),
        ]

        // Create AI Assistant configuration with multi-document JWT
        let configuration = createAIAssistantConfiguration(for: documents)

        // Initialize AI Assistant session with all documents and configuration
        // This allows the AI to work with content from any of the documents
        let aiAssistantSession = AIAssistantSession(documents: documents, configuration: configuration)
        // Initialize the chat UI with the session
        let aiAssistantViewController = AIAssistantViewController(session: aiAssistantSession)

        // Create tabbed PDF view controller for viewing multiple documents
        let tabbedViewController = PDFTabbedViewController()
        tabbedViewController.documents = documents
        tabbedViewController.visibleDocument = documents.first

        // Create a split view controller for showing the AI Assistant alongside the PDF Viewer.
        let presentationController = MultiDocumentAIExampleContainerController(aiAssistantViewController: aiAssistantViewController, tabbedViewController: tabbedViewController)
        presentationController.modalPresentationStyle = .fullScreen
        return presentationController
    }

    /// Creates AI Assistant configuration with multi-document JWT.
    private func createAIAssistantConfiguration(for documents: [Document]) -> AIAssistantConfiguration {
        // When running this example on a device on a machine other than the machine running the AI Assistant demo server,
        // replace the server URL with the IP address of the machine running the demo server.
        let serverURL = URL(string: "http://localhost:4000")!

        let sessionID = "multi-doc-ios-session-id"

        // Create JWT with the document ID that is hexadecimal-encoded
        // and add allowed session IDs for the user.
        let claims: [String: Any] = [
            "document_ids": documents.compactMap { $0.documentId!.hexadecimalEncodedString() },
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

// MARK: - Multi-Document Container

/// Container that manages AI Assistant and document viewer in a split view presentation.
/// This is example code that shows how to use AIAssistantViewController with ModalSidebarSplitViewController.
private class MultiDocumentAIExampleContainerController: ModalSidebarSplitViewController<AIAssistantViewController, PDFTabbedViewController> {

    private var aiAssistantViewController: AIAssistantViewController {
        primaryViewController
    }

    private var tabbedViewController: PDFTabbedViewController {
        secondaryViewController
    }

    init(aiAssistantViewController: AIAssistantViewController, tabbedViewController: PDFTabbedViewController) {
        super.init(primaryViewController: aiAssistantViewController, secondaryViewController: tabbedViewController)

        setupNavigationItems()

        // Set delegate to handle navigation when user taps links in AI Assistant responses
        aiAssistantViewController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - AI Assistant Delegate Integration

extension MultiDocumentAIExampleContainerController: AIAssistantViewControllerDelegate {

    func aiAssistantViewController(_ aiAssistantViewController: AIAssistantViewController, navigateTo document: Document, pageIndex: PageIndex, rects: [CGRect]) {
        // Dismiss AI Assistant if presented modally
        dismissPrimaryIfModal {
            // Perform navigation after modal is dismissed (or immediately if not modal)
            self.performNavigation(aiAssistantViewController, to: document, pageIndex: pageIndex, rects: rects, tabbedViewController: self.tabbedViewController)
        }
    }

    /// Performs the actual navigation to the specified document and location.
    /// Separated into its own method to be called both immediately and after modal dismissal.
    private func performNavigation(_ aiAssistantViewController: AIAssistantViewController, to document: Document, pageIndex: PageIndex, rects: [CGRect], tabbedViewController: PDFTabbedViewController) {
        // Find the document that contains the referenced content
        for tabDocument in tabbedViewController.documents {
            if tabDocument === document {
                // Switch to the correct document if needed
                tabbedViewController.visibleDocument = tabDocument
                break
            }
        }

        // Navigate to the linked rects in the current document and highlight them.
        tabbedViewController.pdfController.setPageIndexWithHighlights(pageIndex, rects)
    }
}

// MARK: - Helpers

extension MultiDocumentAIExampleContainerController {

    private func setupNavigationItems() {
        let pdfController = tabbedViewController.pdfController
        let navigationItem = pdfController.navigationItem
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))

        // togglePrimaryViewController displays the primary controller i.e AIAssistantViewController as a modal in compact widths
        // Otherwise it toggles the sidebar where the primary controller is housed in wider configurations.
        let assistantButton = UIBarButtonItem(image: SDK.imageNamed("ai"), style: .plain, target: self, action: #selector(togglePrimaryViewController))
        assistantButton.title = localizedString("AI Assistant")

        navigationItem.setLeftBarButtonItems([assistantButton], for: .document, animated: false)
        navigationItem.setRightBarButtonItems([doneButton, pdfController.annotationButtonItem], for: .document, animated: false)
    }

    /// Dismisses this view controller
    @objc func dismissSelf() {
        dismiss(animated: true)
    }
}
