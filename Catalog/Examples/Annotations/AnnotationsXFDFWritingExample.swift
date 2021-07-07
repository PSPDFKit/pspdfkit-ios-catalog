//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class AnnotationsXFDFWritingExample: Example {
    override init() {
        super.init()
        title = "XFDF Writing"
        contentDescription = "Custom code that creates annotations in code and exports them as XFDF."
        category = .annotations
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        let documentURL = AssetLoader.assetURL(for: .quickStart)

        let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileXML = docsFolder.appendingPathComponent("XFDFTest.xfdf")
        print("fileXML: \(fileXML.path)")

        // Collect all existing annotations from the document
        let tempDocument = Document(url: documentURL)
        var annotations = [Annotation]()

        let linkAnnotation = LinkAnnotation(url: URL(string: "https://pspdfkit.com")!)
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

        let aVideo2 = LinkAnnotation(url: URL(string: "pspdfkit://[autostart:true]localhost/Bundle/big_buck_bunny.mp4")!)
        aVideo2.boundingBox = CGRect(x: 100, y: 100, width: 200, height: 300)
        aVideo2.pageIndex = 2
        annotations.append(aVideo2)

        let contentMode = UIView.ContentMode.scaleAspectFill.rawValue
        let anImage3 = LinkAnnotation(url: URL(string: "pspdfkit://[contentMode=\(contentMode)]ramitia.files.wordpress.com/2011/05/durian1.jpg")!)
        anImage3.linkType = .image
        anImage3.boundingBox = CGRect(x: 100, y: 100, width: 200, height: 300)
        anImage3.pageIndex = 4
        annotations.append(anImage3)

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
