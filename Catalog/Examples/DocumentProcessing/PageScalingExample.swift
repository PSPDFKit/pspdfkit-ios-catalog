//
//  Copyright © 2016-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// Shows how to scale pages with `PSPDFProcessor`.
final class PageScalingExample: Example {

    // MARK: Lifecycle

    override init() {
        super.init()

        title = "Page Scaling"
        contentDescription = "Shows how to scale pages with PSPDFProcessor"
        category = .documentProcessing
        priority = 13
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)
        return PageScalingPDFViewController(document: document)
    }
}

/// Scales pages of it's document.
private final class PageScalingPDFViewController: PDFViewController {

    // MARK: Lifecycle

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        let actions = [("Page Size", #selector(showPageSize)), ("Scale", #selector(scale))]
        let barButtonItems = actions.map { title, selector in
            UIBarButtonItem(title: title, style: .plain, target: self, action: selector)
        }
        navigationItem.setRightBarButtonItems(barButtonItems.reversed(), for: .document, animated: false)
    }

    // MARK: Bar Button Item Actions

    /// Scales all pages of the current document.
    ///
    /// - Parameter sender: Action sender.
    @objc
    private func scale(_ sender: UIBarButtonItem) {
        guard let document else {
            print("Processor configuration needs a valid document")
            return
        }
        guard let configuration = Processor.Configuration(document: document) else { return }

        // We want to scale down every page to half it's size.
        let newPageSizes: [(PageIndex, CGSize)] = pageSizes!.map { ($0.0, CGSize(width: $0.1!.width / 2, height: $0.1!.height / 2)) }

        for (page, pageSize) in newPageSizes {
            configuration.scalePage(page, to: pageSize)
        }

        let scaledDocumentURL = FileHelper.temporaryPDFFileURL(prefix: "scaled")

        do {
            // Process annotations.
            // `PSPDFProcessor` doesn't modify the document, but creates an output file instead.
            let processor = Processor(configuration: configuration, securityOptions: nil)
            processor.delegate = self
            try processor.write(toFileURL: scaledDocumentURL)
        } catch {
            print("Error while processing document: \(error)")
            return
        }

        presentProcessedDocument(scaledDocumentURL)
    }

    /// Shows the current page size as an alert.
    ///
    /// - Parameter sender: Action sender.
    @objc
    private func showPageSize(_ sender: UIBarButtonItem) {
        let pageSize = pageSizeForPage(at: pageIndex)!
        let message = "Height: \(pageSize.height)\nWidth: \(pageSize.width)"
        let alertController = UIAlertController(title: "Page Size", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Dismiss", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: Helper

    /// Page sizes of the document.
    ///
    /// - Returns: Array of tuples (page number, page size)
    private var pageSizes: [(PageIndex, CGSize?)]? {
        guard let document else { return nil }
        return (0..<document.pageCount).flatMap { [($0, self.pageSizeForPage(at: $0))] }
    }

    /// Gets a page's size.
    ///
    /// - Parameter page: Page to get size from.
    /// - Returns: Page size.
    private func pageSizeForPage(at index: PageIndex) -> CGSize? {
        let pageInfo = document?.pageInfoForPage(at: index)
        return pageInfo?.size
    }

    /// Presents a processed document.
    ///
    /// - Parameter processedDocumentURL: `URL` of processed document.
    private func presentProcessedDocument(_ processedDocumentURL: URL) {
        let processedDocument = Document(url: processedDocumentURL)
        let pdfController = PageScalingPDFViewController(document: processedDocument)
        let rightBarButtonItems = Array(pdfController.navigationItem.rightBarButtonItems(for: .document)!.dropFirst())
        pdfController.navigationItem.setRightBarButtonItems(rightBarButtonItems, for: .document, animated: false)
        let navigationController = UINavigationController(rootViewController: pdfController)
        present(navigationController, animated: true, completion: nil)
    }
}

extension PageScalingPDFViewController: ProcessorDelegate {
    nonisolated func processor(_ processor: Processor, didProcessPage currentPage: UInt, totalPages: UInt) {
        print("Progress: \(currentPage + 1) of \(totalPages)")
    }
}
