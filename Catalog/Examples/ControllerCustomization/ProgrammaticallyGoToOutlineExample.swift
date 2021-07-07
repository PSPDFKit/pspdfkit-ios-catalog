//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class ProgrammaticallyGoToOutlineExample: Example {
    override init() {
        super.init()

        title = "Programmatically Go to a Specific Outline."
        category = .controllerCustomization
        priority = .max
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: document)

        // Check that the PDF has an outline.
        guard let outline = document.outline else {
            return controller
        }

        guard let matchingOutline = matchingOutlineByTitle(outline: outline, title: "Swift 4") else {
            return controller
        }

        controller.setPageIndex(matchingOutline.pageIndex, animated: false)

        return controller
    }

    // Recursive function to find the matching outline element by title.
    private func matchingOutlineByTitle(outline: OutlineElement, title: String) -> OutlineElement! {

        // Return the passed outline if the title matches
        if outline.title == title {
            return outline
        }

        if let children = outline.children {
            // Loop through the outline's children to to find a matching outline
            for child in children {
                // Match found
                if let match = matchingOutlineByTitle(outline: child, title: title) {
                    return match
                }
            }
        }

        return nil
    }
}
