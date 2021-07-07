//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class RotatePageExample: Example {
    override init() {
        super.init()
        title = "Rotate Pages Permanently"
        contentDescription = "Adds a button to rotate pages in 90 degree steps and saves the new orientation."
        category = .documentEditing
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController {
        // Document needs to be in a writable location because rotating changes it.
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)
        return RotatePagePDFViewController(document: document)
    }
}

private class RotatePagePDFViewController: PDFViewController {
    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        let rotatePageButton = UIBarButtonItem(title: "Rotate Page", style: .plain, target: self, action: #selector(rotatePage))
        navigationItem.rightBarButtonItems = [thumbnailsButtonItem, searchButtonItem, rotatePageButton]
    }

    @objc private func rotatePage() {
        guard let document = document, let editor = PDFDocumentEditor(document: document) else {
            print("Document editing not available.")
            return
        }

        // Rotate the first page 90 degrees clockwise. This API can rotate multiple pages at the same time.
        editor.rotatePages([Int(pageIndex)], rotation: 90)

        editor.save { _, error in
            if let error = error {
                print("Error while saving: \(error)")
            } else {
                DispatchQueue.main.async {
                    // Reload the document in the UI.
                    self.reloadData()
                }
            }
        }
    }
}
