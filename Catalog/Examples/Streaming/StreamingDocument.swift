//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

extension Annotation {
    private static var OriginalPageIndexKey = "OriginalPageIndexKey"

    var originalPageIndex: UInt {
        customData?[Annotation.OriginalPageIndexKey] as? UInt ?? 0
    }

    func storeOriginalPageIndex() {
        customData = [Annotation.OriginalPageIndexKey: absolutePageIndex].merging(customData ?? [:]) { _, new in new }
    }
}

final class StreamingDocument: Document {

    var streamingDefinition: StreamingDocumentDefinition
    weak var streamingController: StreamingPDFViewController?

    /// This is the only valid initializer for streaming documents.
    init(streamingDefinition: StreamingDocumentDefinition) {
        self.streamingDefinition = streamingDefinition

        // Build initial set of data providers.
        var pageIndex = 0
        var dataProviders = [DataProviding]()
        for index in streamingDefinition.chunks.indices {
            let url = streamingDefinition.documentURL(chunkIndex: index)
            let fileURL = streamingDefinition.localURLFrom(remoteUrl: url)
            // Check if we already have files on disk
            if FileManager.default.fileExists(atPath: fileURL.path) {
                dataProviders.append(FileDataProvider(fileURL: fileURL))
            } else {
                let data = DataContainerProvider(data: StreamingDocument.blankPDFData(size: streamingDefinition.pageSizes[pageIndex], pages: streamingDefinition.chunks[index]))
                dataProviders.append(data)
            }
            pageIndex += 1
        }
        super.init(dataProviders: dataProviders, loadCheckpointIfAvailable: false)
    }

    /// Filter user-provided annotations for a specific page range.
    func userProvidedAnnotations(pages: Range<Int>) -> [Annotation] {
        streamingDefinition.annotations.annotations.filter { annotation in
            pages.contains(Int(annotation.originalPageIndex))
        }
    }

    override func didCreateDocumentProvider(_ documentProvider: PDFDocumentProvider) -> PDFDocumentProvider {
        // Calculate which chunk we operate on.
        guard let chunkIndex = self.documentProviders.firstIndex(of: documentProvider) else { return documentProvider }
        let pages = streamingDefinition.pagesFor(chunkIndex: chunkIndex)

        // Filter relevant annotations for current chunk
        let userAnnotations = userProvidedAnnotations(pages: pages)

        userAnnotations.forEach { annotation in
            // Annotations need to be converted from their absolute to regular page index
            annotation.pageIndex = annotation.originalPageIndex - documentProvider.pageOffsetForDocument
        }

        // Add custom container before file-provided source
        let container = PDFContainerAnnotationProvider(documentProvider: documentProvider)
        container.setAnnotations(userAnnotations, append: false)
        let annotationManager = documentProvider.annotationManager
        // Force-Unwrap is acceptable here, as per API contract a fresh document provider always has an annotation provider.
        annotationManager.annotationProviders = [container, annotationManager.fileAnnotationProvider!]
        return documentProvider
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Helper to create a blank white PDF with a specific size.
    private static func blankPDFData(size: CGSize, pages: Int = 1) -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height),
                              format: UIGraphicsPDFRendererFormat())
            .pdfData {
                for _ in 0..<pages {
                    $0.beginPage()
                }
            }
    }
}
