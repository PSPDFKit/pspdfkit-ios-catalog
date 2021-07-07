//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

extension UIViewController {
    /// The frontmost presented view controller on top of the receiver.
    var frontmost: UIViewController {
        var topController = self
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }

    /// Presents an alert with the given title, message and a done button.
    public func showAlert(withTitle title: String, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.frontmost.present(alertController, animated: true)
    }

    /// Presents a `UIAlertController` with text fields to enter the desired username and password for the provided URLAuthenticationChallenge.
    /// Primarily used by the examples involving Instant that act as the delegate of `WebExamplesAPIClient`.
    public func presentBasicAuthPrompt(for challenge: URLAuthenticationChallenge, completion: @escaping (_ username: String?, _ password: String?) -> Void) {
        let hudWindow = view.window
        let hudItems = StatusHUD.itemsForHUD(on: hudWindow)
        let alert = UIAlertController(title: "Log in to \(challenge.protectionSpace.host)", message: "Your login information will be sent securely.", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Username"
            textField.text = challenge.proposedCredential?.user
        }

        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            StatusHUD.pushItems(hudItems, on: hudWindow, animated: true) {
                completion(nil, nil)
            }
        }

        let logInAction = UIAlertAction(title: "Log In", style: .default) { [unowned alert] _ in
            guard let textFields = alert.textFields, textFields.count == 2 else {
                StatusHUD.pushItems(hudItems, on: hudWindow, animated: true) {
                    completion(nil, nil)
                }
                return
            }

            let username = textFields[0].text ?? ""
            let password = textFields[1].text ?? ""

            StatusHUD.pushItems(hudItems, on: hudWindow, animated: true) {
                completion(username, password)
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(logInAction)

        StatusHUD.popItems(hudItems, animated: true) {
            self.present(alert, animated: true)
        }
    }
}

extension StatusHUD {

    fileprivate static func popItems(_ items: [StatusHUDItem]?, animated: Bool, completion: @escaping () -> Void) {
        guard let items = items, !items.isEmpty else {
            completion()
            return
        }
        items.dropLast().forEach { $0.pop(animated: true, completion: nil) }
        items.last!.pop(animated: animated, completion: completion)
    }

    fileprivate static func pushItems(_ items: [StatusHUDItem]?, on window: UIWindow?, animated: Bool, completion: @escaping () -> Void) {
        guard let items = items, !items.isEmpty else {
            completion()
            return
        }
        items.dropLast().forEach { $0.push(animated: animated, on: window, completion: nil) }
        items.last!.push(animated: animated, on: window, completion: completion)
    }

}
