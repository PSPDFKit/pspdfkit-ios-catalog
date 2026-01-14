//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

public extension UIColor {

    /// Dynamic brand color.
    @objc(psc_catalogAccentColor)
    class var catalogAccent: UIColor {
        UIColor(named: "accent")!
    }

    /// Returns a random color
    class var random: UIColor {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1.0)
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
        // We are not using `systemFillColor` as it has a lower alpha.
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
