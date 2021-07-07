//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

import Foundation
import SwiftUI

/// Adaptive Stack that changes between VStack and HStack based on the current horizontal size class.
/// @see https://www.hackingwithswift.com/quick-start/swiftui/how-to-automatically-switch-between-hstack-and-vstack-based-on-size-class
struct AdaptiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    private let horizontalAlignment: HorizontalAlignment
    private let verticalAlignment: SwiftUI.VerticalAlignment
    private let spacing: CGFloat?
    private let content: () -> Content

    init(horizontalAlignment: HorizontalAlignment = .center, verticalAlignment: SwiftUI.VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        Group {
            if sizeClass == .compact {
                VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
            } else {
                HStack(alignment: verticalAlignment, spacing: spacing, content: content)
            }
        }
    }
}
