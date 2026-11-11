//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

/// Shows how to use the Nutrient On-Device AI Assistant without its chat UI, through `AIAssistantModelSession`.
///
/// The session runs on the same engine as the On-Device AI Assistant. When the document opens, `prepare()` indexes it
/// on the device: it extracts the text, embeds it, stores it in an on-disk index, and summarizes it. Selecting text or
/// tapping a highlight adds a Study submenu to the SDK’s menu, and the example asks Apple’s on-device model about the
/// passage in two ways:
///
/// - Explain Simply, Even Simpler, Give an Example, Define Key Terms, and How Does This Connect? call
///   `respond(to:generating:scope:)` with app-defined `Generable` types, such as `AIKeyTerms` and `AIConnections`, and
///   get each answer back as a value. Each call runs in a fresh model session with the example’s prompt, so earlier
///   answers don’t affect it. How Does This Connect? uses `.document`, which searches the whole index, and the others
///   use `.nearbyPages(around:radius:)`, which reads the passage’s page and the pages next to it.
/// - Typed questions call `respond(to:scope:)` with `.nearbyPages(around:radius:)`. The session keeps this
///   conversation, so questions can refer to earlier answers.
///
/// The typed values become annotations. Define Key Terms can highlight each term in the passage, with its definition
/// as the highlight’s note. How Does This Connect? quotes related parts of the document, which the example finds in
/// the page text and can highlight in another color. Save as Comment adds an answer as a reply to the passage’s
/// highlight, so the highlight collects a thread of answers. The example checks the model’s words and pages against
/// the document before it marks anything up.
///
/// The example owns the prompts, the scope of each request, and the UI. See the
/// [On-device AI Assistant guide](https://www.nutrient.io/guides/ios/ai-assistant/on-device/) for setup details.
///
/// Requires Apple Intelligence on a supported iPhone, iPad, or Mac running iOS 26, iPadOS 26, or macOS 26 or later.
/// Without it, the document opens normally and the answers explain what’s missing.
class AIStudyCompanionExample: Example {
    override init() {
        super.init()

        title = "AI Study Companion"
        contentDescription = "Select text or tap a highlight for a simple explanation, key terms, related passages, or answers to your questions, and add them to the document as annotations. Runs on device."
        category = .top
        priority = 12
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        guard #available(iOS 26.0, visionOS 26.0, *) else {
            delegate.currentViewController?.showAlert(
                withTitle: "Requires iOS 26",
                message: "AI Study Companion requires an Apple Intelligence-enabled device running iOS 26 or later."
            )
            return nil
        }

        // A research article, as a fresh writable copy each time, so highlights and notes can be saved.
        let document = AssetLoader.writableDocument(for: "Resource Depletion.pdf", overrideIfExists: true)
        return AIStudyPDFViewController(document: document)
    }
}

@available(iOS 26.0, visionOS 26.0, *)
@MainActor
private final class AIStudyPDFViewController: PDFViewController, PDFViewControllerDelegate {
    private let assistant: AIStudyAssistant

    init(document: PSPDFKit.Document) {
        assistant = AIStudyAssistant(document: document)
        super.init(document: document, configuration: PDFConfiguration { builder in
            // Don’t interrupt studying to ask for an author name for highlights.
            builder.shouldAskForAnnotationUsername = false
        })
        delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // The outline’s annotation list shows the highlights and comments the student added.
        navigationItem.setRightBarButtonItems([outlineButtonItem, searchButtonItem], for: .document, animated: false)
        // Prepare while the student reads, so the first answer doesn’t wait for indexing.
        assistant.prepare()
    }

    // MARK: - PDFViewControllerDelegate

    func pdfViewController(_ sender: PDFViewController, menuForText glyphs: GlyphSequence, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        let passage = AIStudyPassage(text: glyphs.text, pageIndex: pageView.pageIndex, boundingBox: glyphs.boundingBox, glyphs: glyphs.glyphs)
        return suggestedMenu.replacingChildren([studyMenu(for: passage)] + suggestedMenu.children)
    }

    func pdfViewController(_ sender: PDFViewController, menuForAnnotations annotations: [Annotation], onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        guard annotations.count == 1, let highlight = annotations.first as? HighlightAnnotation, !highlight.markedUpString.isEmpty else {
            return suggestedMenu
        }
        let passage = AIStudyPassage(text: highlight.markedUpString, pageIndex: highlight.pageIndex, boundingBox: highlight.boundingBox, highlight: highlight)
        return suggestedMenu.replacingChildren([studyMenu(for: passage)] + suggestedMenu.children)
    }

    // MARK: - Studying

    /// Adds a Study submenu to the SDK’s menu for selected text or a highlight.
    private func studyMenu(for passage: AIStudyPassage) -> UIMenu {
        // Ask a Question opens the card without a request, so the student can type one.
        func studyAction(_ request: AIStudyRequest?) -> UIAction {
            UIAction(title: request?.title ?? "Ask a Question…", image: UIImage(systemName: request?.systemImage ?? "questionmark.bubble")) { [weak self] _ in
                self?.presentStudyCard(for: passage, startingWith: request)
            }
        }
        return UIMenu(title: "Study", image: UIImage(systemName: "graduationcap"), children: [
            studyAction(.explainSimply),
            studyAction(.example),
            studyAction(.keyTerms),
            studyAction(.connections),
            studyAction(nil),
        ])
    }

    /// Shows the study card next to the passage. In compact width, the popover becomes a sheet.
    private func presentStudyCard(for passage: AIStudyPassage, startingWith request: AIStudyRequest?) {
        guard let pageView = pageViewForPage(at: passage.pageIndex) else { return }
        let conversation = AIStudyConversation(passage: passage, assistant: assistant)
        if let request {
            conversation.send(request)
        }
        let controller = UIHostingController(rootView: AIStudyCard(conversation: conversation) { [weak self] passage in
            self?.show(passage)
        })
        controller.modalPresentationStyle = .popover
        controller.preferredContentSize = CGSize(width: 400, height: 480)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = pageView
            popover.sourceRect = pageView.convert(passage.boundingBox, from: pageView.pdfCoordinateSpace)
            #if !os(visionOS)
            let sheet = popover.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            // Asking a question brings up the keyboard, so start with room for it.
            sheet.selectedDetentIdentifier = request == nil ? .large : .medium
            sheet.prefersGrabberVisible = true
            #endif
        }
        presentReplacingCurrent(controller)
    }

    /// Closes the study card, goes to the passage’s page, and selects its highlight, or its text so the student can
    /// study it next.
    private func show(_ passage: AIStudyPassage) {
        let showPassage = { [weak self] in
            guard let self else { return }
            setPageIndex(passage.pageIndex, animated: false)
            let pageView = pageViewForPage(at: passage.pageIndex)
            if let highlight = passage.highlight {
                pageView?.select(annotations: [highlight], presentMenu: false, animated: true)
            } else if let glyphs = passage.glyphs {
                pageView?.select(glyphs: glyphs, animated: true)
            }
        }
        if presentedViewController != nil {
            dismiss(animated: true, completion: showPassage)
        } else {
            showPassage()
        }
    }

    private func presentReplacingCurrent(_ controller: UIViewController) {
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                self?.present(controller, animated: true)
            }
        } else {
            present(controller, animated: true)
        }
    }
}
