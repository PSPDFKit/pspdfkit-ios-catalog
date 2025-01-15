//
//  Copyright © 2020-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

enum PrimaryViewState: String, Equatable, LocalizableIterable {
    case annotations = "Annotations"
    case bookmarks = "Bookmarks"
    case outline = "Outline"

    static var allCases: [PrimaryViewState] {
        [.annotations, .bookmarks, .outline]
    }
}

struct SidebarActionHandler {
    var didSelectAnnotation: (Annotation) -> Void
    var didSelectBookmark: (Bookmark) -> Void
    var didSelectOutline: (OutlineElement) -> Void
}

struct CombinedSidebar: View {
    @ObservedObject var document: Document
    @State var pickerState = PrimaryViewState.annotations
    let actionHandler: SidebarActionHandler

    var body: some View {
        switch pickerState {
        case .annotations:
            AnnotationListView(document: document, didSelectAnnotation: actionHandler.didSelectAnnotation)
        case .bookmarks:
            BookmarkListView(document: document, didSelectBookmark: actionHandler.didSelectBookmark)
        case .outline:
            OutlineListView(document: document, didSelectOutline: actionHandler.didSelectOutline)
        }

        Spacer().navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker(selection: $pickerState, label: Text("View State")) {
                        ForEach(PrimaryViewState.allCases, id: \PrimaryViewState.self) { value in
                            Text(value.localizedName).tag(value)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }
            }
    }
}

private struct BookmarkListView: View {
    @ObservedObject var document: Document
    var didSelectBookmark: (Bookmark) -> Void

    var body: some View {
        let bookmarks = document.bookmarks
        List {
            ForEach(bookmarks, id: \.self) { bookmark in
                BookmarkRow(bookmark: bookmark)
                    .onTapGesture {
                        didSelectBookmark(bookmark)
                    }
            }
        }
    }

    struct BookmarkRow: View {
        let bookmark: Bookmark

        var body: some View {
            HStack {
                Text("\(bookmark.displayName)")
                Spacer()
                Text("\(bookmark.pageIndex + 1)")
            }
        }
    }
}

private struct OutlineListView: View {
    @ObservedObject var document: Document
    var didSelectOutline: (OutlineElement) -> Void

    var body: some View {
        let rootOutline = document.outline?.children ?? []
        List(rootOutline, children: \.children) { outlineElement in
            HStack {
                Text("\(outlineElement.title ?? "")")
                Spacer()
                Text("\(outlineElement.pageIndex + 1)")
            }
            .onTapGesture {
                didSelectOutline(outlineElement)
            }
        }
    }
}
