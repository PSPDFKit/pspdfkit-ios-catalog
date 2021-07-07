//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI

extension UIDevice {
    /// Checks if we run in Mac Catalyst Optimized For Mac Idiom
    var isCatalystMacIdiom: Bool {
        if #available(iOS 14, *) {
            return UIDevice.current.userInterfaceIdiom == .mac
        } else {
            return false
        }
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
