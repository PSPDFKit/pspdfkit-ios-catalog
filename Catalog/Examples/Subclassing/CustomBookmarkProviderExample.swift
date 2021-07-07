//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class CustomBookmarkProviderExample: Example {
    override init() {
        super.init()

        title = "Custom Bookmark Provider"
        contentDescription = "Shows how to use a custom bookmark provider using a plist file"
        category = .subclassing
        priority = 250
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .JKHF, overrideIfExists: false)
        document.bookmarkManager?.provider = [BookmarkParser()]

        let controller = PDFViewController(document: document) {
            $0.bookmarkSortOrder = .custom
        }
        controller.navigationItem.setRightBarButtonItems([controller.thumbnailsButtonItem, controller.outlineButtonItem, controller.searchButtonItem, controller.bookmarkButtonItem], for: .document, animated: false)
        return controller
    }
}

class BookmarkParser: NSObject, BookmarkProvider {
    struct CustomBookmark: Codable {
        let identifier: String
        let pageIndex: PageIndex
        let name: String
        let sortKey: Int

        private enum CodingKeys: String, CodingKey {
            case identifier
            case pageIndex
            case name
            case sortKey
        }

        init(bookmark: Bookmark) {
            self.identifier = bookmark.identifier
            self.pageIndex = bookmark.pageIndex
            self.name = bookmark.name?.replacingOccurrences(of: "\"", with: "'") ?? String()
            if let sortKey = bookmark.sortKey {
                self.sortKey = sortKey.intValue
            } else {
                self.sortKey = 0
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(identifier, forKey: .identifier)
            try container.encode(pageIndex, forKey: .pageIndex)
            try container.encode(name, forKey: .name)
            try container.encode(sortKey, forKey: .sortKey)
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            identifier = try values.decode(String.self, forKey: .identifier)
            pageIndex = try values.decode(PageIndex.self, forKey: .pageIndex)
            name = try values.decode(String.self, forKey: .name)
            sortKey = try values.decode(Int.self, forKey: .sortKey)
        }
    }

    var bookmarks: [Bookmark] {
        return self.bookmarkData
    }

    var bookmarkData: [Bookmark]

    override init() {
        self.bookmarkData = BookmarkParser.bookmarkDataFromFile()
        super.init()
    }

    func add(_ bookmark: Bookmark) -> Bool {
        print("Add Bookmark: \(bookmark)")
        let index = bookmarkData.firstIndex(of: bookmark)
        if index == nil || index == NSNotFound {
            bookmarkData.append(bookmark)
        } else {
            bookmarkData[index!] = bookmark
        }
        return true
    }

    func remove(_ bookmark: Bookmark) -> Bool {
        print("Remove Bookmark: \(bookmark)")
        if bookmarkData.contains(bookmark) {
            while let elementIndex = bookmarkData.firstIndex(of: bookmark) {
                bookmarkData.remove(at: elementIndex)
            }
            return true
        } else {
            return false
        }
    }

    func save() {
        print("Save bookmarks.")
        let customBookmarks = bookmarkData.map({ return CustomBookmark(bookmark: $0) })
        let jsonData = try? PropertyListEncoder().encode(customBookmarks)
        try? jsonData?.write(to: BookmarkParser.bookmarkURL()!, options: Data.WritingOptions.atomic)
    }

    // MARK: Helpers

    class func bookmarkURL() -> URL? {
        let applicationSupport = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = applicationSupport?.appendingPathComponent("customBookmarksProvider").appendingPathExtension("plist")
        return fileURL
    }

    class func bookmarkDataFromFile() -> [Bookmark] {
        var bookmarkData = [Bookmark]()

        guard let jsonData = try? Data(contentsOf: BookmarkParser.bookmarkURL()!) else {
            return bookmarkData
        }

        let customBookmark: [CustomBookmark] = try! PropertyListDecoder().decode(Array.self, from: jsonData)
        bookmarkData = customBookmark.map({
            let identifier = $0.identifier
            let pageIndex = $0.pageIndex
            let name = $0.name
            let sortKey = NSNumber(value: $0.sortKey)
            let action = GoToAction(pageIndex: PageIndex(pageIndex))
            return Bookmark(identifier: identifier, action: action, name: name, sortKey: sortKey)
        })

        return bookmarkData
    }
}
