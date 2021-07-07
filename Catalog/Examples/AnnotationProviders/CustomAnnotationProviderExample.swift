//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomAnnotationProviderExample: Example {

    override init() {
        super.init()
        title = "Custom Annotation Provider"
        contentDescription = "Shows how to use a custom annotation provider"
        category = .annotationProviders
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)

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

    /// Backing store for annotations on each page.
    private var annotationDict: [PageIndex: [Annotation]]

    /// Lock for accessing the `annotationDict` backing storage.
    private let annotationDictLock = NSRecursiveLock()

    /// Timer used to used to update annotation color and notify the delegates.
    private var timer: Timer?

    // MARK: - Lifecycle
    override init(documentProvider: PDFDocumentProvider) {
        annotationDict = [:]

        super.init(documentProvider: documentProvider)

        // Add timer in a way so it works while we're dragging pages (NSRunLoopCommonModes).
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerFired(_:)), userInfo: nil, repeats: true)

        // The document provider generation can happen on any thread, make sure we register on the main runloop.
        if let timer = timer {
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
        annotationDictLock.withLock {
            // Return early if we find existing annotations on page.
            if let annotationsOnPage = annotationDict[pageIndex] {
                return annotationsOnPage
            }

            // Create a new note annotation and add it to the backing annotation dictionary storage.
            let documentProvider = providerDelegate?.parentDocumentProvider
            let noteAnnotation = NoteAnnotation()
            noteAnnotation.contents = "Annotation from the custom annotationProvider for page index \(pageIndex)."

            let pageInfo = documentProvider?.document?.pageInfoForPage(at: pageIndex)
            let pageHeight = pageInfo?.size.height ?? 500.0 // Using a fallback page height of 500.

            // Place it on top left (PDF coordinate space starts from bottom left).
            // See https://pspdfkit.com/guides/ios/faq/coordinate-spaces/ for more info.
            noteAnnotation.boundingBox = CGRect(x: 100.0, y: pageHeight - 100.0, width: 32.0, height: 32.0)

            // Set page as the last step.
            noteAnnotation.pageIndex = pageIndex
            annotationDict[pageIndex] = [noteAnnotation]
            noteAnnotation.isEditable = false

            return [noteAnnotation]
        }
    }

    override func add(_ annotations: [Annotation], options: [AnnotationManager.ChangeBehaviorKey: Any]? = nil) -> [Annotation]? {
        super.add(annotations, options: options)

        // Store all the annotations to the custom backing store.
        for annotation in annotations {
            var addedAnnotations: [Annotation]
            if let existingAnnotations = annotationDict[annotation.pageIndex] {
                addedAnnotations = existingAnnotations
                addedAnnotations.append(annotation)
            } else {
                addedAnnotations = [annotation]
            }
            annotationDict[annotation.pageIndex] = addedAnnotations
        }
        return annotations
    }

    // MARK: - Helper

    // Change annotation color and notify the delegate that we have updates.
    @objc func timerFired(_ timer: Timer?) {
        let color = RandomColor()

        // Accessing the annotations backing store for a synchronized access to avoid
        // multithreading issues.
        annotationDictLock.withLock {
            annotationDict.forEach { _, annotationsOnPage in
                annotationsOnPage.forEach { $0.color = color }
                providerDelegate?.update(annotationsOnPage, animated: true)
            }
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
