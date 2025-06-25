//
//  Copyright © 2020-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

struct AnnotationListView: View {
    @ObservedObject var document: Document
    var didSelectAnnotation: (Annotation) -> Void
    @State private var selectedAnnotation: Annotation?
    @StateObject private var data = AnnotationData()

    var body: some View {
        List {
            ForEach(data.sortedPages, id: \.self) { page in
                Section(header: Text("Page \(page + 1)")) {
                    ForEach(data.annotationsPerPage[page]!, id: \.self) { annotation in
                        AnnotationRow(annotation: annotation) {
                            selectedAnnotation = annotation
                            didSelectAnnotation(annotation)
                        }
                    }
                }
            }
            AnnotationCounter(count: data.count)
        }
        .onAppear {
            data.document = document
            data.startObserving()
        }
        .onDisappear {
            data.stopObserving()
        }
        .animation(.default, value: data.annotationsPerPage)
    }
}

private struct AnnotationRow: View {
    @State var annotation: Annotation
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        let useAlpha = annotation.flags.intersection([.invisible, .hidden, .noView]).rawValue.nonzeroBitCount > 0
        let color = UIColor.color(from: annotation.color, withSufficientContrastTo: UIColor.systemBackground)
        let uiImage = annotation.annotationIcon
        let image = uiImage != nil ? Image(uiImage: uiImage!) : Image(systemName: "square.dashed")

        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    image
                        .renderingMode(.template)
                        .foregroundColor(Color(color))
                        .opacity(useAlpha ? 0.5 : 1)
                        .frame(width: 30)

                    VStack {
                        HStack {
                            Text("\(annotation.localizedDescription)")
                            Spacer()
                        }
                        // This might be empty then we don't need to waste space.
                        if !annotation.userAndLastModified.isEmpty {
                            Spacer(minLength: 2)
                            HStack {
                                Text("\(annotation.userAndLastModified)")
                                    .font(.caption)
                                    .foregroundColor(pressed ? .secondary : .primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct AnnotationCounter: View {
    let count: Int

    var body: some View {
        Text(String(format: localizedString("%tu Annotation(s)"), locale: NSLocale.current, arguments: [count]))
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
