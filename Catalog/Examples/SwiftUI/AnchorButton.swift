//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import SwiftUI

/// Wrapper for a regular SwiftUI button that exposes a UIView to anchor popovers.
struct AnchorButton<Content: View>: View {
    typealias Action = (UIView) -> Void
    private let callback: Action
    private let content: Content

    // Workaround for missing @StateObject in iOS 13.
    private struct Store {
        var anchorView = UIView()
    }
    @State private var store = Store()

    init(action: @escaping Action, @ViewBuilder content: () -> Content) {
        self.callback = action
        self.content = content()
    }

    var body: some View {
        return
            ZStack {
                InternalAnchorView(uiView: store.anchorView)
                Button {
                    self.callback(store.anchorView)
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
