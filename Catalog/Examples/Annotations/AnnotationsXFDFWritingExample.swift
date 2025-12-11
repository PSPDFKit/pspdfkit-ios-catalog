//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class AnnotationsXFDFWritingExample: Example {
    override init() {
        super.init()
        title = "XFDF Writing"
        contentDescription = "Creates annotations in code and exports them as XFDF."
        category = .annotations
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let documentURL = AssetLoader.assetURL(for: .welcome)

        let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileXML = docsFolder.appendingPathComponent("XFDFTest.xfdf")
        print("fileXML: \(fileXML.path)")

        // Collect all existing annotations from the document
        let tempDocument = Document(url: documentURL)
        var annotations = [Annotation]()

        let linkAnnotation = LinkAnnotation(url: URL(string: "https://www.nutrient.io/")!)
        linkAnnotation.boundingBox = CGRect(x: 100, y: 80, width: 200, height: 300)
        linkAnnotation.pageIndex = 1
        annotations.append(linkAnnotation)

        let aStream = LinkAnnotation(url: URL(string: "pspdfkit://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!)
        aStream.boundingBox = CGRect(x: 100, y: 100, width: 200, height: 300)
        aStream.pageIndex = 0
        annotations.append(aStream)

        let anImage = LinkAnnotation(url: URL(string: "pspdfkit://ramitia.files.wordpress.com/2011/05/durian1.jpg")!)
        anImage.boundingBox = CGRect(x: 100, y: 100, width: 200, height: 300)
        anImage.pageIndex = 3
        annotations.append(anImage)

        print("annotations: \(annotations)")

        // Write the annotations to the XFDF File.
        do {
            let dataSink = try FileDataSink(fileURL: fileXML)
            try XFDFWriter().write(annotations, to: dataSink, documentProvider: tempDocument.documentProviders.first!)
        } catch {
            print("Failed while coping the existing XFDF file: \(error.localizedDescription)")
        }

        // Create document and set up the XFDF provider
        let document = Document(url: documentURL)
        document.didCreateDocumentProviderBlock = { documentProvider in
            let XFDFProvider = XFDFAnnotationProvider(documentProvider: documentProvider, fileURL: fileXML)
            documentProvider.annotationManager.annotationProviders = [XFDFProvider]
        }

        return PDFViewController(document: document)
    }
}
