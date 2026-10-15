//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

class SingleTapActionExample: Example {

    override init() {
        super.init()

        title = "Custom single tap action"
        contentDescription = "Shows a single tap running custom code instead of toggling the user interface."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let swiftUIView = SingleTapActionExampleView(document: document)
        return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
    }
}

private struct SingleTapActionExampleView: View {
    let document: PSPDFKit.Document
    @PDFView.Scope private var scope

    var body: some View {
        PDFView(document: document)
            .updateConfiguration {
                // Use a view controller subclass that implements the custom tap action.
                $0.overrideClass(PDFViewController.self, with: SingleTapPDFViewController.self)
                // Keep the user interface always visible so the built-in toggle gesture
                // does not consume tap events and the user interface does not auto-hide
                // when changing pages.
                $0.userInterfaceViewMode = .always
            }
            .toolbar {
                DefaultToolbarButtons()
            }
            // The scope allows the toolbar buttons and the PDFView to communicate.
            .pdfViewScope(scope)
    }
}

private class SingleTapPDFViewController: PDFViewController, UIGestureRecognizerDelegate {

    private var tapRecognizer: UITapGestureRecognizer?

    override func documentViewControllerDidLoad() {
        super.documentViewControllerDidLoad()

        // Set up the gesture recognizer for the custom action.
        // For simplicity in this example, we attach the gesture recognizer to the entire document view.
        // This means taps outside of a page still trigger the custom action. If you need to prevent this,
        // use the `gestureRecognizer(_:shouldReceive:)` delegate method to check if the touch is over a
        // page view using `visiblePageView(at:)`.
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(customSingleTapAction))
        tapRecognizer.delegate = self
        documentViewController!.view.addGestureRecognizer(tapRecognizer)

        // Make sure the custom action waits for there not being a second tap, which should zoom instead.
        // The tap recognizer will trigger after a slight delay while it waits for a possible double tap.
        tapRecognizer.require(toFail: interactions.smartZoom)

        self.tapRecognizer = tapRecognizer
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGR: UIGestureRecognizer) -> Bool {
        // Most of Nutrient’s interactions have a visible effect so it's obvious what is consuming a
        // gesture. Text selection is handled by Apple’s UITextInteraction, which has a quirk where it
        // will consume the first tap on the view with no visible effect. This ‘phantom tap’ should
        // happen simultaneously with the custom tap recognizer.
        if gestureRecognizer === tapRecognizer,
          // Apple doesn’t expose the text tap gesture recognizer specifically, so detect it by name.
          // This is known to work across all iOS versions Nutrient supports, but should be re-tested
          // when future versions come out.
          otherGR.name == "UITextInteractionNameSingleTap",
          // Interacting with text in a free text annotation or form field should take
          // precedence over the custom action (so should not recognize simultaneously)
          // so check if the gesture recognizer is part of page text selection.
          interactions.allTextInteractions.contains(otherGR),
          let documentVC = documentViewController,
          let pageView = documentVC.visiblePageView(at: otherGR.location(in: documentVC.view)) {
            // Tap to dismiss text selection should take precedence over the custom action,
            // so only recognize simultaneously when there is no selection.
            return pageView.selectionView.selectedGlyphs.isEmpty
        }
        return false
    }

    @objc private func customSingleTapAction() {
        print("Custom single tap action")
    }
}
