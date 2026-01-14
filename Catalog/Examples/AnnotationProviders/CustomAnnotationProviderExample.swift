//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CustomAnnotationProviderExample: Example {

    override init() {
        super.init()
        title = "Custom Annotation Provider"
        contentDescription = "Shows how to use a custom annotation provider"
        category = .annotationProviders
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)

        document.didCreateDocumentProviderBlock = { documentProvider in
            documentProvider.annotationManager.annotationProviders = [
                // Assign a CustomAnnotationProvider instance as one of the
                // annotation providers for the document.
                CustomAnnotationProvider(documentProvider: documentProvider)
            ]
        }

        let controller = PDFViewController(document: document)
        return controller
    }
}

private class CustomAnnotationProvider: PDFContainerAnnotationProvider {
    /// Timer used to used to update annotation color and notify the delegates.
    private var timer: Timer?

    // MARK: - Lifecycle
    override init(documentProvider: PDFDocumentProvider) {
        super.init(documentProvider: documentProvider)

        // Add timer in a way so it works while we're dragging pages (NSRunLoopCommonModes).
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerFired(_:)), userInfo: nil, repeats: true)

        // The document provider generation can happen on any thread, make sure we register on the main runloop.
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    // MARK: - AnnotationProvider

    /// Backing store for the `AnnotationProvider` protocol's `providerDelegate` property.
    private var providerDelegateBackingStore: AnnotationProviderChangeNotifier?

    override var providerDelegate: AnnotationProviderChangeNotifier? {
        get { providerDelegateBackingStore }
        set {
            guard newValue?.isEqual(providerDelegate) == false else {
                return
            }

            providerDelegateBackingStore = newValue

            // Nil out timer to allow object to deallocate itself.
            if newValue == nil {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    override func annotationsForPage(at pageIndex: PageIndex) -> [Annotation]? {
        // It's important that this method is:
        // - Fast
        // - Thread safe
        // - Caches annotations — Doesn't always create new objects.
        if let cachedAnnotations = performRead({ super.annotationsForPage(at: pageIndex) }) {
            return cachedAnnotations
        }

        // We have nothing cached yet, so populate the cache.
        return performWriteAndWait {
            // Since we left the critical region, another thread may have raced here before.
            // So if we omitted this second check, we would occasionally duplicate annotations!
            if let cachedAnnotations = super.annotationsForPage(at: pageIndex) {
                return cachedAnnotations
            }

            // Create a new note annotation and add it to the backing annotation dictionary storage.
            let documentProvider = providerDelegate?.parentDocumentProvider
            let noteAnnotation = NoteAnnotation()
            noteAnnotation.contents = "Annotation from the custom annotationProvider for page index \(pageIndex)."

            let pageInfo = documentProvider?.document?.pageInfoForPage(at: pageIndex)
            let pageHeight = pageInfo?.size.height ?? 500.0 // Using a fallback page height of 500.

            // Place it on top left (PDF coordinate space starts from bottom left).
            // See https://www.nutrient.io/guides/ios/faq/coordinate-spaces/ for more info.
            noteAnnotation.boundingBox = CGRect(x: 100.0, y: pageHeight - 100.0, width: 32.0, height: 32.0)

            // Set page as the last step, and register the annotation with the backing store.
            noteAnnotation.pageIndex = pageIndex
            noteAnnotation.isEditable = false
            let confirmedAdditions = super.add([noteAnnotation], options: [.suppressNotifications: true])

            // Adding annotations to the backing store typically sets the needs save flag. But if you get the
            // annotations added here from an external file, nothing really changed. So we should make sure to
            // clear this flag if we have no dirty annotations.
            if dirtyAnnotations?.isEmpty ?? true {
                clearNeedsSaveFlag()
            }

            return confirmedAdditions
        }
    }

    // MARK: - Helper

    // Change annotation color and notify the delegate that we have updates.
    @objc func timerFired(_ timer: Timer?) {
        let color = RandomColor()

        // Accessing the annotations backing store for a synchronized access to avoid
        // multithreading issues.
        let cachedAnnotations = performRead {
            annotationCache as! [Int: [Annotation]]
        }
        cachedAnnotations.forEach { _, annotationsOnPage in
            annotationsOnPage.forEach { $0.color = color }
            providerDelegate?.update(annotationsOnPage, animated: true)
        }
    }
}

// MARK: - Private

// Helper to generate a random color.
private func RandomColor() -> UIColor? {
    let hue = CGFloat.random(in: 0...1.0)
    let saturation = CGFloat.random(in: 0.5...1.0) //  0.5 to 1.0, away from white
    let brightness = CGFloat.random(in: 0.5...1.0) //  0.5 to 1.0, away from black
    return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
}
