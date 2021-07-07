//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class AnnotationProviderWithRotationExample: Example {

    override init() {
        super.init()

        title = "Custom Annotation Provider With Serialization and Rotation"
        contentDescription = "A custom annotation provider that serializes its annotations shown working with temporary page rotations."
        category = .annotationProviders
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: AssetName.quickStart)
        document.didCreateDocumentProviderBlock = { documentProvider in
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let dataDirectory = cachesDirectory.appendingPathComponent("AnnotationProviderWithRotationExample", isDirectory: true)
            try! FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: nil)
            let storageURL = dataDirectory.appendingPathComponent("\(document.uid!).annotations", isDirectory: false)

            let customProvider = AnnotationProvider(storageFileURL: storageURL, documentProvider: documentProvider)
            // Include the default file annotation provider so it can load links and form elements from the PDF.
            let fileAnnotationProvider = documentProvider.annotationManager.fileAnnotationProvider!
            documentProvider.annotationManager.annotationProviders = [customProvider, fileAnnotationProvider]
        }
        return RotatePageTemporarilyExample.RotatePagePDFViewController(document: document) {
            $0.pageMode = .single
        }
    }

    /// A custom annotation provider that loads from, and saves to, a file.
    ///
    /// This is only useful as an example. In practice this technique is for when you have a custom annotation backend
    /// such as a database. If you just want to save annotations to an external file in an archive, do not use a custom
    /// annotation provider and instead set the document’s `annotationSaveMode` to `PSPDFAnnotationSaveModeExternalFile`.
    private class AnnotationProvider: PDFContainerAnnotationProvider {

        let storageFileURL: URL

        init(storageFileURL: URL, documentProvider: PDFDocumentProvider) {
            self.storageFileURL = storageFileURL
            super.init(documentProvider: documentProvider)

            guard let data = try? Data(contentsOf: storageFileURL) else {
                // Most likely the file does not exist. Don’t care.
                return
            }
            let annotations = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, Annotation.self], from: data)
            add(annotations as! [Annotation], options: nil)
        }

        override func saveAnnotations(options: [String: Any]? = nil) throws {
            let data = try NSKeyedArchiver.archivedData(withRootObject: allAnnotations as NSArray, requiringSecureCoding: true)
            try data.write(to: storageFileURL)
        }
    }
}
