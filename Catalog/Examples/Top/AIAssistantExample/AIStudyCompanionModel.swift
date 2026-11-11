//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import FoundationModels
import Observation
import PSPDFKit

// MARK: - Passages and requests

/// Text the student selected or highlighted, or that the model quoted from another part of the document.
struct AIStudyPassage {
    let text: String
    let pageIndex: PageIndex
    /// The passage’s glyphs, used to highlight it. A passage from a highlight doesn’t have them.
    var glyphs: [Glyph]?
    /// The highlight the passage came from, or the one created to save an answer or mark a related passage.
    var highlight: HighlightAnnotation?
    /// Where the passage is on its page, in PDF coordinates.
    let boundingBox: CGRect

    init(text: String, pageIndex: PageIndex, boundingBox: CGRect, glyphs: [Glyph]? = nil, highlight: HighlightAnnotation? = nil) {
        // Page text keeps the layout’s line breaks. Join words hyphenated across lines, and use single spaces.
        self.text = text
            .replacingOccurrences(of: #"(?<=\p{L})-\s*\n\s*(?=\p{Ll})"#, with: "", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        self.pageIndex = pageIndex
        self.boundingBox = boundingBox
        self.glyphs = glyphs
        self.highlight = highlight
    }

    /// The indexes of the passage’s glyphs on its page, from the selection or from the text under its highlight.
    func glyphRange(on parser: TextParser) -> ClosedRange<Int>? {
        let glyphs = glyphs ?? parser.glyphs.filter { glyph in
            let center = CGPoint(x: glyph.frame.midX, y: glyph.frame.midY)
            return highlight?.rects?.contains { $0.contains(center) } ?? false
        }
        guard let first = glyphs.map(\.indexOnPage).min(), let last = glyphs.map(\.indexOnPage).max() else { return nil }
        return first...last
    }
}

extension TextParser {
    /// The glyphs where the page first reads `phrase`, ignoring case, accents, punctuation, line breaks, and
    /// hyphenation, or `nil` if the page doesn’t contain it. Pass `glyphRange` to search only part of the page.
    ///
    /// The model can change a word or quote loosely, so the app looks for its text on the page before marking it up.
    func glyphs(reading phrase: String, within glyphRange: ClosedRange<Int>? = nil) -> [Glyph]? {
        let target = Self.comparableLetters(in: phrase)
        guard !target.isEmpty else { return nil }
        // The page’s letters and digits in reading order, which is the order of `glyphs`, each with the index of its
        // glyph. Comparing letters instead of words finds words hyphenated across lines, such as “reason-” and “ing”.
        // A match must start and end where a word does, so a term doesn’t match part of a longer word.
        var letters: [Character] = []
        var letterGlyphs: [Int] = []
        var starts: [Int] = []
        var ends: Set<Int> = []
        var isWordStart = true
        for glyph in glyphs where glyphRange?.contains(glyph.indexOnPage) ?? true {
            let glyphLetters = Self.comparableLetters(in: glyph.content)
            if glyphLetters.isEmpty {
                // Spaces and punctuation end a word. Glyphs without content fill in after ligatures, inside a word.
                if !glyph.content.isEmpty {
                    ends.insert(letters.count)
                    isWordStart = true
                }
                continue
            }
            if isWordStart {
                starts.append(letters.count)
                isWordStart = false
            } else if letters.last?.isLetter == true, glyphLetters.first?.isNumber == true {
                // A footnote number can follow a word without a space, as in “ordering2”.
                ends.insert(letters.count)
            }
            letters += glyphLetters
            letterGlyphs += repeatElement(glyph.indexOnPage, count: glyphLetters.count)
            if glyph.lineBreaker {
                ends.insert(letters.count)
                isWordStart = true
            }
        }
        ends.insert(letters.count)
        for start in starts where ends.contains(start + target.count) && letters[start...].starts(with: target) {
            let first = letterGlyphs[start]
            let last = letterGlyphs[start + target.count - 1]
            return glyphs(in: NSRange(location: first, length: last - first + 1))
        }
        return nil
    }

    /// The letters and digits in `text`, in lowercase and without accents. PDF text can use ligatures, such as “ﬁ” in
    /// “scientiﬁc”, or draw an accent as its own glyph, so they’re split into letters and accents first.
    private static func comparableLetters(in text: String) -> [Character] {
        Array(
            text.precomposedStringWithCompatibilityMapping
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                .filter { $0.isLetter || $0.isNumber }
        )
    }
}

/// What a student can ask about a passage, and the instruction the model gets for it.
enum AIStudyRequest: Hashable {
    case explainSimply
    case simpler
    case example
    case keyTerms
    case connections
    case question(String)

    /// Follow-ups offered once there’s an answer.
    static let followUps: [Self] = [.simpler, .example, .keyTerms, .connections]

    var title: String {
        switch self {
        case .explainSimply: "Explain Simply"
        case .simpler: "Even Simpler"
        case .example: "Give an Example"
        case .keyTerms: "Define Key Terms"
        case .connections: "How Does This Connect?"
        case .question(let question): question
        }
    }

    var systemImage: String {
        switch self {
        case .explainSimply: "sparkles"
        case .simpler: "wand.and.stars"
        case .example: "lightbulb"
        case .keyTerms: "character.book.closed"
        case .connections: "point.3.connected.trianglepath.dotted"
        case .question: "questionmark.bubble"
        }
    }

    var instruction: String {
        switch self {
        case .explainSimply:
            "Explain this passage in plain words for a student who is new to the topic: what it says and why it matters. Use one everyday comparison if it helps, and keep the passage’s facts accurate."
        case .simpler:
            "Explain this passage again, more simply: at most two short sentences in common words. Keep the facts accurate."
        case .example:
            "Give one concrete example from everyday life that shows the idea in this passage. Describe a situation a student would recognize instead of restating the passage."
        case .keyTerms:
            "List up to four key terms from this passage and what each one means here, in plain words."
        case .connections:
            // The page numbers the model names can be wrong. The app checks the page of each quote instead, so the summary
            // shouldn’t mention pages.
            "How does the idea in this passage connect to the rest of the document? Explain the related ideas without mentioning page numbers, and quote up to three related parts of the document word for word."
        case .question(let question):
            "Answer this question about the passage in a few short sentences: \(question)"
        }
    }

    var isQuestion: Bool {
        if case .question = self {
            return true
        }
        return false
    }
}

/// An explanation of a passage, generated in the app’s own type.
@available(iOS 26.0, visionOS 26.0, *)
@Generable(description: "An explanation of a passage for a student who is new to the topic")
struct AIExplanation {
    @Guide(description: "The explanation, in short sentences with common words")
    var text: String
}

/// An everyday example of the idea in a passage.
@available(iOS 26.0, visionOS 26.0, *)
@Generable(description: "An everyday example of the idea in a passage")
struct AIExample {
    @Guide(description: "One concrete situation from everyday life that shows the idea, in two or three sentences")
    var text: String
}

/// The key terms in a passage, which the app can find in the passage and highlight.
@available(iOS 26.0, visionOS 26.0, *)
@Generable(description: "The key terms in a passage, with what each one means")
struct AIKeyTerms {
    @Generable
    struct Term {
        @Guide(description: "The term exactly as the passage writes it")
        var term: String

        @Guide(description: "What the term means in the passage, in one short sentence with common words")
        var definition: String
    }

    @Guide(description: "The most important terms in the passage", .count(1...4))
    var terms: [Term]
}

/// How a passage connects to the rest of the document, with quotes the app can find and highlight.
@available(iOS 26.0, visionOS 26.0, *)
@Generable(description: "How a passage connects to other parts of the document")
struct AIConnections {
    @Generable
    struct RelatedPart {
        @Guide(description: "Five to twelve words copied exactly from a related part of the document, not from the passage")
        var quote: String

        @Guide(description: "The zero-based index of the page the quote is on")
        var pageIndex: Int

        @Guide(description: "How that part relates to the passage, in one short sentence")
        var connection: String
    }

    @Guide(description: "How the passage connects to the rest of the document, in two or three short sentences")
    var summary: String

    @Guide(description: "Related parts of the document", .count(1...3))
    var relatedParts: [RelatedPart]
}

/// An answer, with the typed values that the app uses to mark up the document.
@available(iOS 26.0, visionOS 26.0, *)
struct AIStudyAnswer {
    /// The answer as text, to read, copy, or save as a comment.
    let text: String
    /// The terms that Define Key Terms explained.
    var keyTerms: [AIKeyTerms.Term] = []
    /// The parts of the document that How Does This Connect? quoted, and that the app found.
    var relatedPassages: [AIRelatedPassage] = []
}

/// A part of the document that relates to the passage, and how.
struct AIRelatedPassage: Identifiable {
    let id = UUID()
    let connection: String
    var passage: AIStudyPassage
}

// MARK: - Model session

/// Prepares the document once with the headless `AIAssistantModelSession`, and sends it one request at a time.
@available(iOS 26.0, visionOS 26.0, *)
@MainActor
final class AIStudyAssistant {
    private enum Status {
        case preparing
        case ready
        case unavailable(String)
    }

    let document: Document
    private var status = Status.preparing

    private var session: AIAssistantModelSession?
    private var preparation: Task<Void, Never>?
    private var isHandlingRequest = false
    private var waitingRequests: [CheckedContinuation<Void, Never>] = []

    /// Long selections are shortened to leave room in the model’s context window for the nearby pages.
    private static let passageLengthLimit = 1_000

    init(document: Document) {
        self.document = document
    }

    /// Starts preparing the document, which extracts, embeds, and summarizes its text on device. It does nothing
    /// while preparation is running or once the document is ready.
    func prepare() {
        guard preparation == nil else { return }
        if case .ready = status { return }
        preparation = Task {
            defer { preparation = nil }
            status = .preparing
            do {
                if let reason = Self.reason(for: SystemLanguageModel.default.availability) {
                    throw AIStudyError(message: reason)
                }
                let session = try session ?? AIAssistantModelSession(document: document)
                self.session = session
                try await session.prepare()
                status = .ready
            } catch {
                status = .unavailable(error.localizedDescription)
            }
        }
    }

    /// Answers a request about a passage.
    ///
    /// All requests except typed questions call `respond(to:generating:scope:)` with the app’s own types. Each call runs
    /// in a fresh model session with only the app’s prompt and text from the document, so earlier answers can’t leak in.
    /// Even Simpler gets the explanation to simplify in its prompt for this reason. How Does This Connect? searches
    /// the whole document, and the others read the passage’s page and the pages next to it.
    ///
    /// Typed questions call `respond(to:scope:)`, the assistant’s question answering. It keeps answers short and
    /// grounded in the document, and remembers earlier questions and answers. One session serves the whole document,
    /// so that history includes other passages too. Each prompt repeats its passage for this reason.
    func answer(_ request: AIStudyRequest, about passage: AIStudyPassage, simplifying explanation: String? = nil) async throws -> AIStudyAnswer {
        var prompt = """
            \(request.instruction)

            Passage from page \(passage.pageIndex + 1):
            “\(passage.text.prefix(Self.passageLengthLimit))”
            """
        if request == .simpler, let explanation {
            prompt += "\n\nMake it simpler than this earlier explanation, and use a different comparison: “\(explanation)”"
        }
        let nearbyPages = AIAssistantModelSession.RetrievalScope.nearbyPages(around: passage.pageIndex, radius: 1)
        return try await withPreparedSession { session in
            switch request {
            case .explainSimply, .simpler:
                let explanation = try await session.respond(to: prompt, generating: AIExplanation.self, scope: nearbyPages)
                return AIStudyAnswer(text: explanation.text)
            case .example:
                let example = try await session.respond(to: prompt, generating: AIExample.self, scope: nearbyPages)
                return AIStudyAnswer(text: example.text)
            case .keyTerms:
                let terms = try await session.respond(to: prompt, generating: AIKeyTerms.self, scope: nearbyPages).terms
                return AIStudyAnswer(text: terms.map { "\($0.term): \($0.definition)" }.joined(separator: "\n"), keyTerms: terms)
            case .connections:
                let connections = try await session.respond(to: prompt, generating: AIConnections.self, scope: .document)
                return AIStudyAnswer(text: connections.summary, relatedPassages: relatedPassages(connections.relatedParts, outside: passage))
            case .question:
                return AIStudyAnswer(text: try await session.respond(to: prompt, scope: nearbyPages))
            }
        }
    }

    /// Finds each quote in the document, and skips quotes from the passage itself. The model can quote loosely or name
    /// the wrong page, so the app looks on the page it named and the pages next to it, and drops quotes it can’t find.
    private func relatedPassages(_ parts: [AIConnections.RelatedPart], outside passage: AIStudyPassage) -> [AIRelatedPassage] {
        let passageGlyphs = document.textParserForPage(at: passage.pageIndex).flatMap(passage.glyphRange(on:))
        var relatedPassages: [AIRelatedPassage] = []
        for part in parts {
            let pages = [part.pageIndex, part.pageIndex - 1, part.pageIndex + 1]
                .filter { (0..<Int(document.pageCount)).contains($0) }
                .map { PageIndex($0) }
            for pageIndex in pages {
                guard let glyphs = document.textParserForPage(at: pageIndex)?.glyphs(reading: part.quote),
                      let first = glyphs.first else { continue }
                let isInPassage = pageIndex == passage.pageIndex && passageGlyphs?.contains(first.indexOnPage) == true
                let isFound = relatedPassages.contains { $0.passage.pageIndex == pageIndex && $0.passage.glyphs?.first?.indexOnPage == first.indexOnPage }
                if !isInPassage && !isFound {
                    let boundingBox = glyphs.map(\.frame).reduce(CGRect.null) { $0.union($1) }
                    relatedPassages.append(AIRelatedPassage(
                        connection: part.connection,
                        passage: AIStudyPassage(text: part.quote, pageIndex: pageIndex, boundingBox: boundingBox, glyphs: glyphs)
                    ))
                }
                break
            }
        }
        return relatedPassages
    }

    private func withPreparedSession<Result>(_ request: (AIAssistantModelSession) async throws -> Result) async throws -> Result {
        // The session handles one request at a time, so later requests wait for their turn.
        while isHandlingRequest {
            await withCheckedContinuation { waitingRequests.append($0) }
        }
        isHandlingRequest = true
        defer {
            isHandlingRequest = false
            if !waitingRequests.isEmpty {
                waitingRequests.removeFirst().resume()
            }
        }
        // A request canceled while it waited, for example because its card was closed, doesn’t need to run.
        try Task.checkCancellation()

        do {
            return try await request(preparedSession())
        } catch AIAssistantModelSessionError.documentNotPrepared {
            // Saving the PDF makes the prepared index outdated. Autosave runs, for example, when the app goes to the
            // background. Prepare the saved document, then try once more.
            status = .preparing
            return try await request(preparedSession())
        }
    }

    private func preparedSession() async throws -> AIAssistantModelSession {
        if case .ready = status, let session {
            return session
        }
        // Starts or joins preparation, and retries it if it failed, for example before the student turned on
        // Apple Intelligence.
        prepare()
        await preparation?.value
        try Task.checkCancellation()
        switch status {
        case .ready:
            if let session {
                return session
            }
        case .unavailable(let message):
            throw AIStudyError(message: message)
        case .preparing:
            break
        }
        throw AIStudyError(message: "The document isn’t ready yet. Try again.")
    }

    private static func reason(for availability: SystemLanguageModel.Availability) -> String? {
        switch availability {
        case .available: nil
        case .unavailable(.deviceNotEligible): "This device doesn’t support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled): "Turn on Apple Intelligence in Settings, then try again."
        case .unavailable(.modelNotReady): "Apple Intelligence is still downloading its model. Try again later."
        case .unavailable: "Apple Intelligence isn’t available right now."
        }
    }
}

struct AIStudyError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

// MARK: - Conversations

/// The requests and answers about one passage, and the annotations the student adds from them.
@available(iOS 26.0, visionOS 26.0, *)
@MainActor
@Observable
final class AIStudyConversation {
    struct Turn: Identifiable {
        let id = UUID()
        let request: AIStudyRequest
        var answer: AIStudyAnswer?
        var error: String?
        var isSaved = false
        /// The number of key terms or related passages highlighted, once the student asked for it.
        var markedUpCount: Int?
    }

    private(set) var passage: AIStudyPassage
    private(set) var turns: [Turn] = []

    var isResponding: Bool {
        turns.last.map { $0.answer == nil && $0.error == nil } ?? false
    }

    var title: String {
        guard let request = turns.first?.request, !request.isQuestion else { return "Ask a Question" }
        return request.title
    }

    @ObservationIgnored private let assistant: AIStudyAssistant
    @ObservationIgnored private var task: Task<Void, Never>?

    private var document: Document { assistant.document }

    init(passage: AIStudyPassage, assistant: AIStudyAssistant) {
        self.passage = passage
        self.assistant = assistant
    }

    func send(_ request: AIStudyRequest) {
        guard !isResponding else { return }
        // Explanations don’t see earlier answers, so Even Simpler gets the latest one on this card.
        let explanation = turns.filter { $0.request == .explainSimply || $0.request == .simpler }.compactMap(\.answer?.text).last
        turns.append(Turn(request: request))
        let index = turns.count - 1
        task = Task {
            do {
                turns[index].answer = try await assistant.answer(request, about: passage, simplifying: explanation)
            } catch is CancellationError {
                turns[index].error = "Stopped."
            } catch {
                turns[index].error = error.localizedDescription
            }
        }
    }

    /// Sends the last request again after it failed.
    func retryLastRequest() {
        guard !isResponding, let turn = turns.last, turn.error != nil else { return }
        turns.removeLast()
        send(turn.request)
    }

    func cancel() {
        task?.cancel()
    }

    /// Saves the answer as a reply to the passage’s highlight, highlighting the passage first if needed. The highlight
    /// collects the saved answers as a comment thread, which the SDK shows when the student opens its note.
    func saveAsComment(_ turn: Turn) {
        guard let answer = turn.answer, let index = turns.firstIndex(where: { $0.id == turn.id }),
              let highlight = passage.highlight ?? highlightPassage() else { return }
        let reply = NoteAnnotation(contents: "\(turn.request.title)\n\(answer.text)")
        reply.user = "AI Study Companion"
        reply.pageIndex = highlight.pageIndex
        reply.boundingBox = CGRect(x: highlight.boundingBox.minX, y: highlight.boundingBox.maxY - 32, width: 32, height: 32)
        reply.inReplyTo = highlight
        guard document.add(annotations: [reply]) else { return }
        turns[index].isSaved = true
    }

    /// Highlights each key term in the passage in its own color, with its definition as the highlight’s note, so the
    /// student can tap the term on the page to read it again. Terms the model didn’t write as the passage does aren’t
    /// highlighted.
    func highlightKeyTerms(from turn: Turn) {
        guard let terms = turn.answer?.keyTerms, let index = turns.firstIndex(where: { $0.id == turn.id }) else { return }
        let parser = document.textParserForPage(at: passage.pageIndex)
        let passageGlyphs = parser.flatMap(passage.glyphRange(on:))
        let highlights = terms.compactMap { term -> HighlightAnnotation? in
            guard let passageGlyphs, let glyphs = parser?.glyphs(reading: term.term, within: passageGlyphs),
                  let highlight = HighlightAnnotation.textOverlayAnnotation(with: glyphs) else { return nil }
            highlight.pageIndex = passage.pageIndex
            highlight.color = .systemPink
            highlight.contents = "\(term.term): \(term.definition)"
            return highlight
        }
        if highlights.isEmpty || document.add(annotations: highlights) {
            turns[index].markedUpCount = highlights.count
        }
    }

    /// Highlights the related passages in another color, with how each one connects as its note.
    func highlightRelatedPassages(from turn: Turn) {
        guard var answer = turn.answer, let index = turns.firstIndex(where: { $0.id == turn.id }) else { return }
        let excerpt = passage.text.count > 80 ? "\(passage.text.prefix(80))…" : passage.text
        var highlights: [HighlightAnnotation] = []
        for relatedIndex in answer.relatedPassages.indices {
            let related = answer.relatedPassages[relatedIndex]
            guard let glyphs = related.passage.glyphs,
                  let highlight = HighlightAnnotation.textOverlayAnnotation(with: glyphs) else { continue }
            highlight.pageIndex = related.passage.pageIndex
            highlight.color = .systemTeal
            highlight.contents = "\(related.connection)\n\nRelated to page \(passage.pageIndex + 1): “\(excerpt)”"
            highlights.append(highlight)
            answer.relatedPassages[relatedIndex].passage.highlight = highlight
        }
        if highlights.isEmpty || document.add(annotations: highlights) {
            turns[index].answer = answer
            turns[index].markedUpCount = highlights.count
        }
    }

    /// Highlights the selected passage, so answers can be saved on it.
    private func highlightPassage() -> HighlightAnnotation? {
        guard let glyphs = passage.glyphs,
              let highlight = HighlightAnnotation.textOverlayAnnotation(with: glyphs) else { return nil }
        highlight.pageIndex = passage.pageIndex
        guard document.add(annotations: [highlight]) else { return nil }
        passage.highlight = highlight
        return highlight
    }
}
