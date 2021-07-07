//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class RotatePageTemporarilyExample: Example {

    override init() {
        super.init()

        title = "Rotate pages temporarily"
        contentDescription = "Adds a button to rotate pages temporarily in 90 degree steps without writing changes to the PDF."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: AssetName.quickStart)
        let controller = RotatePagePDFViewController(document: document) {
            $0.pageMode = .single
        }
        return controller
    }

    // MARK: Controller

    class RotatePagePDFViewController: PDFViewController {

        // MARK: Lifecycle
        override func commonInit(with document: Document?, configuration: PDFConfiguration) {
            super.commonInit(with: document, configuration: configuration)

            let rotatePageButton = UIBarButtonItem(title: "Rotate Page", style: .plain, target: self, action: #selector(rotatePage))
            navigationItem.setRightBarButtonItems([thumbnailsButtonItem, searchButtonItem, rotatePageButton], animated: false)
        }

        // MARK: - Actions

        @objc func rotatePage() {
            guard let document = self.document else {
                return
            }
            if !document.isValid {
                return
            }
            let currentPageIndex = self.pageIndex
            let currentRotation = document.pageInfoForPage(at: currentPageIndex)!.rotationOffset
            let documentProvider = document.documentProviderForPage(at: currentPageIndex)

            // Increment the rotation by 90 degrees. The supported rotation values are 0, 90, 180 or 270.
            let updatedRotation = Rotation(rawValue: (currentRotation.rawValue + 90) % 360)!

            // Rotates the current page.
            documentProvider?.setRotationOffset(updatedRotation, forPageAt: currentPageIndex)

            // Clear the cache for the rotated page, to trigger a re-render.
            SDK.shared.cache.invalidateImages(from: document, pageIndex: currentPageIndex)

            // Reloading the data is required because the document is currently displayed in a `PDFViewController`.
            reloadData()
        }
    }
}
