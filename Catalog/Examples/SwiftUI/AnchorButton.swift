//
//  Copyright © 2020-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

/// Wrapper for a regular SwiftUI button that exposes a UIView to anchor popovers.
@MainActor struct AnchorButton<Content: View>: View {
    typealias Action = (UIView) -> Void
    private let callback: Action
    private let content: Content
    @State private var anchorView = UIView()

    init(action: @escaping Action, @ViewBuilder content: () -> Content) {
        self.callback = action
        self.content = content()
    }

    var body: some View {
        ZStack {
            InternalAnchorView(uiView: anchorView)
            Button {
                self.callback(anchorView)
            } label: {
                content
            }
        }
    }

    private struct InternalAnchorView: UIViewRepresentable {
        typealias UIViewType = UIView
        let uiView: UIView

        func makeUIView(context: Self.Context) -> Self.UIViewType {
            uiView
        }

        func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) { }
    }
}
