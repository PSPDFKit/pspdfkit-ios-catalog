//
//  Copyright © 2020-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

extension UIDevice {
    /// Checks if we run in Mac Catalyst Optimized For Mac Idiom
    var isCatalystMacIdiom: Bool {
        UIDevice.current.userInterfaceIdiom == .mac
    }
}

struct PressedCapturingButtonStyle: ButtonStyle {
    @Binding var pressed: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        pressed = configuration.isPressed
        return configuration.label
            .background(configuration.isPressed ? Color.blue : Color.clear)
    }
}

extension Color {
    /// Simple helper to add hex colors.
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

extension UIHostingController {
    /// Helper that makes setting the large title property simple.
    convenience init(rootView: Content, largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode) {
        self.init(rootView: rootView)
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
    }
}
