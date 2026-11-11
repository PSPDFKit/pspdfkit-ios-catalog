//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import SwiftUI

// MARK: - Studying a passage

/// A compact card next to the selected text, with the answers and a composer for follow-ups.
@available(iOS 26.0, visionOS 26.0, *)
struct AIStudyCard: View {
    let conversation: AIStudyConversation
    /// Closes the card and shows a passage on its page.
    let showPassage: (AIStudyPassage) -> Void

    @State private var question = ""
    @FocusState private var isAsking: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding(20)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(conversation.passage.text)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    ForEach(Array(conversation.turns.enumerated()), id: \.element.id) { index, turn in
                        AIStudyTurnView(
                            turn: turn,
                            conversation: conversation,
                            showsTitle: index > 0 || turn.request.isQuestion,
                            canRetry: index == conversation.turns.count - 1,
                            showPassage: showPassage
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            Divider()
            composer
        }
        .task {
            // Focus the question field for Ask a Question once the card has appeared.
            guard conversation.turns.isEmpty else { return }
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                return
            }
            isAsking = true
        }
        .onDisappear {
            conversation.cancel()
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            Menu("Follow Up", systemImage: "sparkles") {
                ForEach(AIStudyRequest.followUps, id: \.self) { request in
                    Button(request.title, systemImage: request.systemImage) { conversation.send(request) }
                }
            }
            .labelStyle(.iconOnly)
            .disabled(conversation.isResponding || conversation.turns.isEmpty)

            TextField(conversation.turns.isEmpty ? "Ask anything about this passage" : "Ask a follow-up", text: $question)
                .textFieldStyle(.plain)
                .focused($isAsking)
                .submitLabel(.send)
                .onSubmit(ask)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12), in: Capsule())

            Button(action: ask) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .disabled(conversation.isResponding || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Ask")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func ask() {
        let question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !conversation.isResponding else { return }
        conversation.send(.question(question))
        self.question = ""
    }
}

@available(iOS 26.0, visionOS 26.0, *)
private struct AIStudyTurnView: View {
    let turn: AIStudyConversation.Turn
    let conversation: AIStudyConversation
    let showsTitle: Bool
    let canRetry: Bool
    let showPassage: (AIStudyPassage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsTitle {
                Label(turn.request.title, systemImage: turn.request.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if let answer = turn.answer {
                if answer.keyTerms.isEmpty {
                    Text(answer.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    keyTerms(answer.keyTerms)
                }
                if !answer.relatedPassages.isEmpty {
                    relatedPassages(answer.relatedPassages)
                }
                markUpButton(for: answer)
                Button(turn.isSaved ? "Saved as Comment" : "Save as Comment", systemImage: turn.isSaved ? "checkmark.circle.fill" : "text.bubble") {
                    conversation.saveAsComment(turn)
                }
                .disabled(turn.isSaved)
                .font(.subheadline)
                .buttonStyle(.borderless)
            } else if let error = turn.error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                if canRetry {
                    Button("Try Again") { conversation.retryLastRequest() }
                        .buttonStyle(.bordered)
                }
            } else {
                ProgressView("Thinking…")
                    .font(.subheadline)
            }
        }
    }

    private func keyTerms(_ terms: [AIKeyTerms.Term]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(terms.enumerated()), id: \.offset) { _, term in
                VStack(alignment: .leading, spacing: 2) {
                    Text(term.term)
                        .fontWeight(.semibold)
                    Text(term.definition)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The parts of the document that the answer quoted. Tapping one closes the card and shows it on its page.
    private func relatedPassages(_ passages: [AIRelatedPassage]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(passages) { related in
                Button {
                    showPassage(related.passage)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("“\(related.passage.text)”")
                            .italic()
                        Text(related.connection)
                            .foregroundStyle(.secondary)
                        Label("Page \(related.passage.pageIndex + 1)", systemImage: "arrow.turn.down.right")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.teal.opacity(0.12), in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Highlights the key terms in the passage or the related passages, then says how many it highlighted.
    @ViewBuilder private func markUpButton(for answer: AIStudyAnswer) -> some View {
        let highlightsTerms = !answer.keyTerms.isEmpty
        if let highlightedCount = turn.markedUpCount {
            Label(
                highlightsTerms ? Self.highlighted(highlightedCount, "term", none: "None of the terms are in the passage")
                    : Self.highlighted(highlightedCount, "passage", none: "Couldn’t highlight the passages"),
                systemImage: highlightedCount == 0 ? "info.circle" : "checkmark.circle.fill"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } else if highlightsTerms {
            Button("Highlight Terms in Passage", systemImage: "highlighter") { conversation.highlightKeyTerms(from: turn) }
                .buttonStyle(.bordered)
        } else if !answer.relatedPassages.isEmpty {
            Button("Highlight Related Passages", systemImage: "highlighter") { conversation.highlightRelatedPassages(from: turn) }
                .buttonStyle(.bordered)
        }
    }

    private static func highlighted(_ count: Int, _ noun: String, none: String) -> String {
        switch count {
        case 0: none
        case 1: "Highlighted 1 \(noun)"
        default: "Highlighted \(count) \(noun)s"
        }
    }
}
