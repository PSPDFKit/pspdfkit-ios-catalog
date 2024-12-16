//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Set your license key here. Nutrient is commercial software.
        // Each Nutrient license is bound to a specific app bundle id.
        // Visit https://my.nutrient.io to get your demo or commercial license key.
        SDK.setLicenseKey("YOUR_LICENSE_KEY_GOES_HERE")

        // Set up the default style for Nutrient Catalog.
        setupDefaultAppearance()

        // Example how to customize appearance of navigation bars and toolbars.
        // customizeAppearanceOfNavigationBar()
        // customizeAppearanceOfToolbar()

        // Example how to easily change certain images in Nutrient.
        // customizeImages()

        // Example how to localize strings in Nutrient.
        // customizeLocalization()

        if ProcessInfo.processInfo.arguments.contains("--clear-all-caches") {
            SDK.shared.cache.clear()
        }

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure callback for Open In Chrome feature. Optional.
        SDK.shared[SDK.Setting.xCallbackURLString] = "pspdfcatalog://"
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.sceneClass = UIWindowScene.self
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    private func setupDefaultAppearance() {
        // Set up the default navigation bar style.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        let normalProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [PDFNavigationController.self])
        let popoverProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [PDFNavigationController.self, UIPopoverPresentationController.self])
        normalProxy.standardAppearance = appearance
        normalProxy.compactAppearance = appearance
        popoverProxy.standardAppearance = appearance
        popoverProxy.compactAppearance = appearance
    }

    // MARK: - Customization

    private func customizeImages() {
        SDK.shared.imageLoadingHandler = { imageName in
            if imageName == "knob" {
                UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
                    UIBezierPath(rect: context.format.bounds).fill()
                }
            }
            return nil
        }
    }

    private func customizeLocalization() {
        // Either use the block-based system.
        setLocalizationClosure { stringToLocalize in
            guard let stringToLocalize else { return nil }
            // This will look up strings in language/PSPDFKit.strings inside resources.
            // (In Catalog, there are no such files, this is just to demonstrate best practice)
            return NSLocalizedString(stringToLocalize, tableName: "PSPDFKit", bundle: .main, value: "", comment: "")
            // return String("_____\(stringToLocalize)_____")
        }

        // Or override via dictionary.
        // See PSPDFKit.bundle/en.lproj/PSPDFKit.strings for all available strings.
        setLocalizationDictionary([
            "en": [
                "%tu of %tu": "Page %tu of %tu",
                "%tu–%tu of %tu": "Pages %tu–%tu of %tu"
            ]
        ])
    }

    private func customizeAppearanceOfNavigationBar() {
        // Use dynamic colors for light mode and dark mode.
        let backgroundColor = UIColor {
            $0.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1) : UIColor(red: 1, green: 0.72, blue: 0.3, alpha: 1)
        }
        let foregroundColor = UIColor {
            $0.userInterfaceStyle == .dark ? UIColor(red: 1, green: 0.8, blue: 0.5, alpha: 1) : UIColor(white: 0, alpha: 1)
        }

        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: foregroundColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: foregroundColor]
        appearance.backgroundColor = backgroundColor

        let appearanceProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [PDFNavigationController.self])
        appearanceProxy.standardAppearance = appearance
        appearanceProxy.compactAppearance = appearance
        appearanceProxy.scrollEdgeAppearance = appearance
        appearanceProxy.tintColor = foregroundColor

        // Repeat the same customization steps for
        // [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[PSPDFNavigationController.class, UIPopoverPresentationController.class]];
        // if you want to customize the look of navigation bars in popovers on iPad as well.
    }

    private func customizeAppearanceOfToolbar() {
        // Use dynamic colors for light mode and dark mode.
        let backgroundColor = UIColor {
            $0.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1) : UIColor(red: 0.77, green: 0.88, blue: 0.65, alpha: 1)
        }
        let foregroundColor = UIColor {
            $0.userInterfaceStyle == .dark ? UIColor(red: 0.86, green: 0.93, blue: 0.78, alpha: 1) : UIColor(white: 0, alpha: 1)
        }

        let appearance = UIToolbarAppearance()
        appearance.backgroundColor = backgroundColor

        let appearanceProxy = FlexibleToolbar.appearance()
        appearanceProxy.standardAppearance = appearance
        appearanceProxy.compactAppearance = appearance
        appearanceProxy.tintColor = foregroundColor
    }
}
