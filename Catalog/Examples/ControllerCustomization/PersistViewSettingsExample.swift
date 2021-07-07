//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class PersistViewSettingsExample: Example, PDFViewControllerDelegate {
    let pageTransition = "pageTransition"
    let pageMode = "pageMode"
    let scrollDirection = "scrollDirection"
    let spreadFitting = "spreadFitting"

    override init() {
        super.init()

        title = "Persist View Settings"
        contentDescription = "Shows how to persist PDFSettingsViewController options using UserDefaults."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let controller = PDFViewController(document: document, delegate: self) {
            // Configure the `PDFSettingsViewController`'s options.
            $0.settingsOptions = [.pageTransition, .pageMode, .scrollDirection, .spreadFitting]

            // Restore the settings from the user defaults.
            let defaults = UserDefaults.standard
            $0.pageTransition = PageTransition(rawValue: UInt(defaults.integer(forKey: self.pageTransition)))!
            $0.pageMode = PageMode(rawValue: UInt(defaults.integer(forKey: self.pageMode)))!
            $0.scrollDirection = ScrollDirection(rawValue: UInt(defaults.integer(forKey: self.scrollDirection)))!
            $0.spreadFitting = PDFConfiguration.SpreadFitting(rawValue: defaults.integer(forKey: self.spreadFitting))!
        }

        // Configure the left bar button items.
        controller.navigationItem.setLeftBarButtonItems([controller.settingsButtonItem], animated: false)
        controller.navigationItem.leftItemsSupplementBackButton = true
        return controller
    }

    // MARK: - PDFViewControllerDelegate
    func pdfViewControllerDidDismiss(_ pdfController: PDFViewController) {
        // Persist the settings options in the user defaults.
        let defaults = UserDefaults.standard
        defaults.set(pdfController.configuration.pageTransition.rawValue, forKey: pageTransition)
        defaults.set(pdfController.configuration.pageMode.rawValue, forKey: pageMode)
        defaults.set(pdfController.configuration.scrollDirection.rawValue, forKey: scrollDirection)
        defaults.set(pdfController.configuration.spreadFitting.rawValue, forKey: spreadFitting)
    }
}
