//
//  Copyright © 2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import AVFAudio

class CustomSpeakMenuItemExample: Example, PDFViewControllerDelegate {
    lazy var speechSynthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()

        title = "Custom Speak Menu Item"
        contentDescription = "Replace the system Speak menu item to change the speech rate, pitch or language."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)
        let controller = AdaptivePDFViewController(document: document)
        controller.delegate = self
        return controller
    }

    func pdfViewController(_ sender: PDFViewController, menuForText glyphs: GlyphSequence, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        // Remove the system speak menu.
        var children = suggestedMenu.children.filter { menuElement in
            if let menu = menuElement as? UIMenu {
                menu.identifier != .speech
            } else {
                true
            }
        }

        // Add our custom speak action.
        let text = glyphs.text
        if text.isEmpty == false {
            let speakAction = UIAction(title: "Speak 🗣️") { _ in
                let utterance = AVSpeechUtterance(string: text)
                // We’ll just set the rate and pitch here. The voice/language could also be set.
                // The language could be guessed using NLLanguageRecognizer.
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                utterance.pitchMultiplier = 2
                self.speechSynthesizer.speak(utterance)
            }
            children.insert(speakAction, at: 0)
        }

        return suggestedMenu.replacingChildren(children)
    }
}
