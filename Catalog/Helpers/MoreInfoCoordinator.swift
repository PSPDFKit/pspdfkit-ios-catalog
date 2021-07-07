//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class MoreInfoCoordinator {

    private let title: String
    private let exampleDescription: String?
    private let url: URL?
    private let defaultsKey: String
    private weak var presentationContext: UIViewController?

    init(with example: IndustryExample, presentationContext: UIViewController) {
        self.title = example.title
        self.exampleDescription = example.extendedDescription
        self.url = example.url
        self.defaultsKey = String(describing: type(of: example.self)) + "Key"
        self.presentationContext = presentationContext
    }

    lazy var barButton: UIBarButtonItem = {
        let moreInfoButton = UIButton(type: .detailDisclosure)
        moreInfoButton.addTarget(self, action: #selector(didTapMoreInfoButton(_:)), for: .touchUpInside)
        return UIBarButtonItem(customView: moreInfoButton)
    }()

    func showAlertIfNeeded() {
        if !UserDefaults.standard.bool(forKey: defaultsKey) && !UserDefaults.standard.bool(forKey: "skipIndustryExamplesAlerts") {
            self.showMoreInfoAlert()
            UserDefaults.standard.set(true, forKey: self.defaultsKey)
        }
    }

    @objc private func didTapMoreInfoButton(_ sender: UIButton) {
        showMoreInfoAlert()
    }

    private func showMoreInfoAlert() {
        guard let presentationContext = presentationContext, let exampleDescription = exampleDescription else {
            return
        }

        let alertController = UIAlertController(title: self.title, message: exampleDescription, preferredStyle: .alert)
        if let url = url {
            let learnMoreAction = UIAlertAction(title: "Learn More...", style: .default, handler: { _ in
                UIApplication.shared.open(url)
            })
            alertController.addAction(learnMoreAction)
        }
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))

        // Override the alert's user interface style to match its presentation context.
        alertController.overrideUserInterfaceStyle = presentationContext.traitCollection.userInterfaceStyle
        presentationContext.present(alertController, animated: true, completion: nil)
    }
}
