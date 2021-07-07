//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit
import PSPDFKitUI

class BookmarkUIExample: Example {

    override init() {
        super.init()
        title = "Custom Bookmark Name UI"
        contentDescription = "Shows a UI window where you can name your bookmarks while creating them."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        let pdfController = CustomBookmarkPDFViewController(document: document)
        return pdfController
    }
}

// MARK: Controller

private class CustomBookmarkPDFViewController: PDFViewController {

    // MARK: Lifecycle
    public override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        bookmarkButtonItem.action = #selector(bookmarkButtonTapped)
        navigationItem.rightBarButtonItems = [thumbnailsButtonItem, activityButtonItem, outlineButtonItem, bookmarkButtonItem]
    }

    // MARK: - Actions
    @objc func bookmarkButtonTapped() {
        guard let bookmarkManager = document?.bookmarkManager else {
            print("Couldn't get bookmark manager.")
            return
        }

        // We need to properly handle adding and removing bookmarks
        if bookmarkManager.bookmarkForPage(at: pageIndex) == nil {
            let alert = UIAlertController(title: nil, message: "Please name your bookmark:", preferredStyle: .alert)
            // We need a mutable copy since we can't edit the name of the bookmark otherwise
            let mutableBookmark = MutableBookmark(pageIndex: pageIndex)

            alert.addTextField { textField in
                // This will be the dault name of the bookmark if not name is entered into the text field
                textField.placeholder = "Page \(self.pageIndex + 1)"
            }

            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                // We us the content of the textfield as the name of the bookmark
                mutableBookmark.name = alert.textFields![0].text
                bookmarkManager.addBookmark(mutableBookmark)
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)

            alert.addAction(cancelAction)
            alert.addAction(okAction)
            present(alert, animated: true)
        } else {
            bookmarkManager.removeBookmarksForPage(at: pageIndex)
        }
    }
}
