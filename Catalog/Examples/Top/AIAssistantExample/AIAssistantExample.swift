//
//  Copyright © 2025 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// Example that shows how to use Nutrient AI Assistant.
/// In order to run this example, you will need to run the AI Assistant demo server locally.
/// You can do this by cloning the repository at https://github.com/PSPDFKit/ai-assistant-demo and following the instructions in the README.
/// Once the demo server is running, you can use the AI Assistant via the toolbar button to interact with the document.
class AIAssistantExample: Example {
    override init() {
        super.init()

        title = "AI Assistant"
        contentDescription = "AI chat for intelligent document analysis and interaction. You must also run the AI Assistant demo server on your Mac."
        category = .top
        priority = 20
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: "Resource Depletion.pdf", overrideIfExists: false)

        // When running this example on a device on a machine other than the machine running the AI Assistant demo server,
        // replace the server URL with the IP address of the machine running the demo server.
        let serverURL = URL(string: "http://localhost:4000")!

        let sessionID = "my-ios-session"
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
            delegate.currentViewController?.showAlert(withTitle: "Couldn’t Set Up AI Assistant", message: "Couldn’t create JWT: \(error)")
            return nil
        }

        let controller = PDFViewController(document: document) {
            // Create and set configuration that is used to setup the AI Assistant.
            $0.aiAssistantConfiguration = AIAssistantConfiguration(serverURL: serverURL, jwt: jwt, sessionID: sessionID)
        }

        // Add the AI Assistant button to the navigation bar.
        controller.navigationItem.setRightBarButtonItems([controller.aiAssistantButtonItem], for: .document, animated: false)

        let moreInfoButton = UIBarButtonItem(customView: UIButton(type: .detailDisclosure, primaryAction: UIAction { _ in
            self.presentMoreInfoAlertController(from: controller)
        }))
        controller.navigationItem.setLeftBarButtonItems([moreInfoButton], for: .document, animated: false)
        controller.navigationItem.leftItemsSupplementBackButton = true

        return controller
    }

    private func presentMoreInfoAlertController(from controller: UIViewController) {
        let description = "For this example you will need to run the AI Assistant demo server locally. You can do this by cloning the repository and following the instructions in the README. Once the demo server is running, you can use the AI Assistant on a simulator via the toolbar button to interact with the document."
        let alertController = UIAlertController(title: "AI Assistant", message: description, preferredStyle: .alert)
        let url = "https://github.com/PSPDFKit/ai-assistant-demo"
        let learnMoreAction = UIAlertAction(title: "Copy repository URL", style: .default) { _ in
            UIPasteboard.general.string = url
        }
        alertController.addAction(learnMoreAction)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        controller.present(alertController, animated: true, completion: nil)
    }
}

private extension Data {
    /// Converts data to hexadecimal format
    /// - Returns: Hexadecimal string or nil if conversion fails
    func hexadecimalEncodedString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
