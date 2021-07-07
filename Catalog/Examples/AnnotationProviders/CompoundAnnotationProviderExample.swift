//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class CompoundAnnotationProviderExample: Example {

    override init() {
        super.init()
        title = "Compound Annotation Provider"
        contentDescription = "A custom annotation provider that lazily loads its annotations and combines them with annotations from the PDF document."
        category = .annotationProviders
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)
        document.didCreateDocumentProviderBlock = { documentProvider in
            if let fileAnnotationProvider = documentProvider.annotationManager.fileAnnotationProvider {
                documentProvider.annotationManager.annotationProviders = [
                    CompoundAnnotationProvider(documentProvider: documentProvider, fileAnnotationProvider: fileAnnotationProvider),
                ]
            }
        }
        return AdaptivePDFViewController(document: document)
    }

}

private class CompoundAnnotationProvider: PDFContainerAnnotationProvider {

    init(documentProvider: PDFDocumentProvider, fileAnnotationProvider: PDFFileAnnotationProvider) {
        self.fileAnnotationProvider = fileAnnotationProvider
        super.init(documentProvider: documentProvider)
    }

    /// Reference to the original file annotation provider.
    let fileAnnotationProvider: PDFFileAnnotationProvider

    /// Page indices for which we have lazily loaded the annotations.
    var loadedPageIndices: Set<PageIndex> = []

    override func annotationsForPage(at pageIndex: PageIndex) -> [Annotation]? {
        // First, fetch the annotations from the file annotation provider. Use
        // `annotationsForPage(at:)` because this is the function that actually
        // loads the annotations.
        let fileAnnotations = fileAnnotationProvider.annotationsForPage(at: pageIndex) ?? []
        // Then, merge them with the custom annotations.
        let customAnnotations = customAnnotationsForPage(at: pageIndex)
        return fileAnnotations + customAnnotations
    }

    private func customAnnotationsForPage(at pageIndex: PageIndex) -> [Annotation] {
        // If we loaded our custom annotations into the cache, ask `super` to
        // retrieve them from cache within the same critical region for reading
        // to achieve atomicity.
        let cachedCustomAnnotations = performRead {
            loadedPageIndices.contains(pageIndex) ? super.annotationsForPage(at: pageIndex) : nil
        }
        if let cachedCustomAnnotations = cachedCustomAnnotations {
            return cachedCustomAnnotations
        }
        // Otherwise, we need to load the custom annotations and load them
        // into the cache. We need to do all that within a critical region.
        return performWriteAndWait {
            // Because we had to leave the critical region from reading to
            // writing, another thread could have raced here before us. In order
            // to prevent caching the same custom annotations multiple times, we
            // must check our bookkeeping first. Reads can be nested in writes,
            // so calling `super` here is fine.
            if loadedPageIndices.contains(pageIndex) {
                let cachedCustomAnnotations = super.annotationsForPage(at: pageIndex) ?? []
                return cachedCustomAnnotations
            }
            // For the sake of this example, we simulate loading annotations by
            // generating random squares.
            let loadedCustomAnnotations = makeSquares(at: pageIndex)
            // Because adding annotations to the cache can fail and the return
            // value can differ, we need to account for that when doing our
            // bookkeeping.
            guard let addedCustomAnnotations = super.add(loadedCustomAnnotations, options: nil) else {
                return []
            }
            // Now that we know caching succeeded, do the bookkeeping and return
            // the added custom annotations.
            loadedPageIndices.insert(pageIndex)
            return addedCustomAnnotations
        }
    }

    override func add(_ annotations: [Annotation], options: [AnnotationManager.ChangeBehaviorKey: Any]? = nil) -> [Annotation]? {
        // For each annotation being added here, make sure we have loaded the
        // custom annotations at the page they're supposed to be on.
        for annotation in annotations {
            _ = customAnnotationsForPage(at: annotation.pageIndex)
        }
        return super.add(annotations, options: options)
    }

    override var allowAnnotationZIndexMoves: Bool {
        // Because this annotation provider merges annotations from two sources,
        // z-index moves could have unreliable results. It's better to disable
        // them altogether.
        false
    }

    override func insert(_ annotation: Annotation, atZIndex destinationIndex: UInt, options: [AnnotationManager.ChangeBehaviorKey: Any]? = nil) throws {
        // Since z-index moves are disabled, we should always throw here.
        throw PSPDFKitError(.cannotModifyAnnotationZIndices)
    }

    override var shouldSaveAnnotations: Bool {
        // Because this implementation doesn't actually load annotations from
        // any store, we don't support saving.
        false
    }

    override func saveAnnotations(options: [String: Any]? = nil) throws {
        // Since saving is disabled, we should always throw here.
        throw PSPDFKitError(.annotationSavingDisabled)
        // If your custom annotation store supports wtiting on a per-page basis,
        // and you don't do that immediately when adding annotations, you will
        // have to make sure that the custom annotations for all pages have been
        // cached before. In any case, any actual saving operation would need to
        // be wrapped in its entirety in a critical region for writing, using
        // `performWriteAndWait`.
    }

}

private func makeSquares(at pageIndex: PageIndex) -> [SquareAnnotation] {
    let left = SquareAnnotation()
    left.color = .systemRed
    left.fillColor = .systemTeal
    left.boundingBox = CGRect(x: 50, y: 50, width: 100, height: 100)
    left.pageIndex = pageIndex
    let right = SquareAnnotation()
    right.color = .systemGreen
    right.fillColor = .systemPink
    right.boundingBox = CGRect(x: 200, y: 50, width: 100, height: 100)
    right.pageIndex = pageIndex
    return [left, right]
}
