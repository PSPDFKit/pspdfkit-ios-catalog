//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

private extension ThumbnailViewFilter {
    static let inkAnnotations = ThumbnailViewFilter("Ink Annotations")
}

private class CustomThumbnailViewController: ThumbnailViewController {
    override func pages(forFilter filter: ThumbnailViewFilter, groupingResultsBy groupSize: UInt, result resultHandler: @escaping (IndexSet) -> Void, completion: @escaping (Bool) -> Void) -> PSPDFKit.Progress? {
        // Only shows pages with ink annotations.
        if filter == .inkAnnotations {
            guard let pagesWithInkAnnotations = document?.allAnnotations(of: .ink).map({ $0.key.intValue }) else { return nil }

            var annotationIndexes: IndexSet = []
            pagesWithInkAnnotations.forEach { annotationIndexes.insert($0) }

            resultHandler(annotationIndexes)
            completion(true)
        }

        return super.pages(forFilter: filter, groupingResultsBy: groupSize, result: resultHandler, completion: completion)
    }
}

class CustomThumbnailViewControllerFilterExample: Example {
    override init() {
        super.init()

        title = "Custom Thumbnail View Controller Filter"
        contentDescription = "Shows how to add a custom filter by subclassing ThumbnailViewController"
        category = .subclassing
        priority = 400
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Playground is convenient for testing
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let controller = PDFViewController(document: document) {
            // Register the override to use a custom search thumbnail view controller subclass.
            $0.overrideClass(ThumbnailViewController.self, with: CustomThumbnailViewController.self)
        }
        controller.navigationItem.rightBarButtonItems = [controller.thumbnailsButtonItem]

        // Add the custom filter option.
        controller.thumbnailController.filterOptions = [.showAll, .bookmarks, .inkAnnotations]
        return controller
    }
}
