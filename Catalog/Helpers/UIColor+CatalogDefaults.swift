//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

public extension UIColor {

    /// Dynamic brand color on iOS 13 and above.
    /// Falls back to a static color on iOS 12. Same as light mode color on iOS 13.
    @objc(psc_catalogTintColor)
    class var catalogTint: UIColor {
        return UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.660, green: 0.750, blue: 0.970, alpha: 1.0)
            } else {
                return UIColor(red: 0.270, green: 0.210, blue: 0.890, alpha: 1.0)
            }
        })
    }

    /// Gives `UIColor.label`.
    @objc(psc_labelColor)
    class var psc_label: UIColor {
        return UIColor.label
    }

    /// Gives `UIColor.secondaryLabel`.
    @objc(psc_secondaryLabelColor)
    class var psc_secondaryLabel: UIColor {
        return UIColor.secondaryLabel
    }

    /// Gives `UIColor.systemGray3`.
    @objc(psc_accessoryViewColor)
    class var psc_accessoryView: UIColor {
        // We are not using systemFillColor as it has a lower alpha compared to one on iOS 12.
        return UIColor.systemGray3
    }

    /// Gives `UIColor.systemBackground`.
    @objc(psc_systemBackgroundColor)
    class var psc_systemBackground: UIColor {
        return UIColor.systemBackground
    }

    /// Gives `UIColor.secondarySystemBackground`.
    @objc(psc_secondarySystemBackgroundColor)
    class var psc_secondarySystemBackground: UIColor {
        return UIColor.secondarySystemBackground
    }

    /// Gives `UIColor.systemGroupedBackground`.
    @objc(psc_systemGroupedBackgroundColor)
    class var psc_systemGroupedBackground: UIColor {
        return UIColor.systemGroupedBackground
    }

    /// Gives `UIColor.tertiarySystemFill`.
    @objc(psc_tertiarySystemFillColor)
    class var psc_tertiarySystemFill: UIColor {
        return UIColor.tertiarySystemFill
    }
}
