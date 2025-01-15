//
//  Copyright © 2014-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

// MARK: - XFDF Annotation Provider

class XFDFAnnotationProviderExample: Example {

    override init() {
        super.init()
        title = "XFDF Annotation Provider"
        contentDescription = "XFDF is an XML-based Adobe standard and is well suited for importing and exporting for integration with third-party PDF applications."
        category = .annotationProviders
        priority = 80
    }

    // This example shows how you can create an XFDF provider instead of the default file-based one.
    // XFDF is an industry standard and the file will be interoperable with Adobe Acrobat or any other standards-compliant PDF framework.
    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let documentURL = AssetLoader.assetURL(for: .annualReport)

        // Load from an example XFDF file.
        let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileXML = docsFolder.appendingPathComponent("XFDFTest.xfdf")
        print("Using XFDF file at \(fileXML.path)")

        // DEBUG HELPER: Delete the existing file.
        // try? FileManager.default.removeItem(at: fileXML)

        // Create an example XFDF from the current document if one doesn't already exist.
        if !FileManager.default.fileExists(atPath: fileXML.path) {
            // Collect all existing annotations from the document.
            let tempDocument = Document(url: documentURL)
            let annotations = tempDocument.allAnnotations(of: .all).values.flatMap { $0 }

            // Write the annotations to the disk creating a new XFDF file.
            do {
                let dataSink = try FileDataSink(fileURL: fileXML)
                try XFDFWriter().write(annotations, to: dataSink, documentProvider: tempDocument.documentProviders.first!)
            } catch {
                print("Failed to write XFDF file: \(error.localizedDescription)")
                return nil
            }
        }

        // Create document and set up the XFDF provider.
        let document = Document(url: documentURL)
        document.annotationSaveMode = .externalFile
        document.didCreateDocumentProviderBlock = { documentProvider in
            let XFDFProvider = XFDFAnnotationProvider(documentProvider: documentProvider, fileURL: fileXML)
            // Note that if the document you're opening has form fields which you wish to be usable when using XFDF, you should also add the file annotation
            // provider to the annotation manager's `annotationProviders` array:
            //
            // let fileProvider = documentProvider.annotationManager.fileAnnotationProvider!
            // documentProvider.annotationManager.annotationProviders = [XFDFProvider, fileProvider]

            documentProvider.annotationManager.annotationProviders = [XFDFProvider]
        }

        let controller = PDFViewController(document: document)

        let saveButton = UIBarButtonItem(title: "Save", primaryAction: UIAction { _ in
            document.save { result in

                switch result {
                case .success:
                    let attributes = try? Foundation.FileManager.default.attributesOfItem(atPath: fileXML.path)
                    let XFDFFileSize = attributes?[.size] as? UInt64 ?? 0
                    print("Saving done. (XFDF file size: \(XFDFFileSize) bytes)")

                case .failure(let error):
                    print("Saving failed: \(error.localizedDescription)")
                }
            }
        })
        controller.navigationItem.leftBarButtonItems = [controller.closeButtonItem, saveButton]
        return controller
    }
}
