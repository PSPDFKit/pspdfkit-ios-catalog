//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKitUI

/// Demonstrates how to configure `PDFViewController` to use a custom `inputAccessoryView` when
/// creating or editing `FreeTextAnnotation`. In addition, it draws attention to the key sources
/// of mistakes that would lead to visual glitches or no visible `inputAccessoryView` at all.
class CustomFreeTextInputAccessoryExample: Example {
    override init() {
        super.init()

        title = "Custom Free Text inputAccessory"
        category = .annotations
    }

    /// A FreeTextAnnotationView that installs a custom `inputAccessoryView` for editing the text of
    /// its annotation.
    ///
    /// The custom view is useless but very visible.
    class UselessInputAccessoryFreeTextAnnotationView: FreeTextAnnotationView {

        override func textViewForEditing() -> UITextView {
            let textView = super.textViewForEditing()
            // UIKit will only adjust the size if we help it a bit
            let uselessAccessory = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 42)))
            uselessAccessory.autoresizingMask = .flexibleWidth

            // For an accessory view that uses autolayout, like UIToolbar, the above would be:
            // let uselessAccessory = UIToolbar()
            // uselessAccessory.translatesAutoresizingMaskIntoConstraints = false

            // shine bright like a diamond…
            uselessAccessory.backgroundColor = .cyan

            // install the accessory view
            textView.inputAccessoryView = uselessAccessory

            return textView
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        return PDFViewController(document: document) {
            // register our custom class
            $0.overrideClass(FreeTextAnnotationView.self, with: UselessInputAccessoryFreeTextAnnotationView.self)

            /*
             If we do not set this to false, PSPDFKit’s default accessory view will be installed in
             a way that makes it impossible to replace without visual glitches.
             */
            $0.freeTextAccessoryViewEnabled = false
        }
    }
}
