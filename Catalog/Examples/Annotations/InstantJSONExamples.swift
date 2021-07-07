//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

private
func withFirstProvider<T>(of document: Document, perform: (PDFDocumentProvider) -> T ) -> T {
    return perform(document.documentProviders.first!)
}

class InstantJSONAnnotationExample: Example {
    override init() {
        super.init()

        title = "Instant JSON - Annotation"
        contentDescription = "Convert an annotation to and from Instant JSON."
        category = .annotations
        priority = 300
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)

        // Generally the annotation's Instant JSON is stored and loaded from an external file. In this example, we are using a hardcoded string that matches the Instant JSON.
        let inkAnnotationJsonString = """
        {
            "bbox": [89.586334228515625, 98.5791015625, 143.12948608398438, 207.1583251953125],
            "isDrawnNaturally": false,
            "lineWidth": 5,
            "lines": {
                "intensities": [
                    [0.5, 0.5, 0.5],
                    [0.5, 0.5, 0.5]
                ],
                "points": [
                    [[92.086334228515625, 101.07916259765625], [92.086334228515625, 202.15826416015625], [138.12950134277344, 303.2374267578125]],
                    [[184.17266845703125, 101.07916259765625], [184.17266845703125, 202.15826416015625], [230.2158203125, 303.2374267578125]]
                ]
            },
            "opacity": 1,
            "pageIndex": 0,
            "strokeColor": "#AA47BE",
            "type": "pspdfkit/ink",
            "v": 1
        }
        """

        // Convert the JSON string to NSData
        let data = inkAnnotationJsonString.data(using: .utf8)!

        let annotation = withFirstProvider(of: document) {
            // Create annotation from Instant JSON data.
            return try! Annotation(fromInstantJSON: data, documentProvider: $0)
        }

        // Add the the newly created annotation to the document.
        document.add(annotations: [annotation])

        let controller = InstantJSONAnnotationPDFController(document: document)
        let exportButton = UIBarButtonItem(title: "Export Instant JSON", style: .plain, target: controller, action: #selector(InstantJSONAnnotationPDFController.exportInstantJSON(_:)))
        controller.navigationItem.rightBarButtonItems = [exportButton]
        return controller
    }

    // MARK: Controller

    class InstantJSONAnnotationPDFController: PDFViewController {

        // MARK: Actions

        @objc func exportInstantJSON(_ sender: AnyObject) {

            // The document's first ink annotation on the first page.
            let inkAnnotation = self.document!.annotationsForPage(at: 0, type: .ink).first!

            // Generate Instant JSON data for the Ink annotation.
            let data = try! inkAnnotation.generateInstantJSON()

            // Convert the data to JSON string.
            let jsonString = String(data: data, encoding: .utf8)

            // The data should be stored in an external file. In this example we simply display in an alert.
            let alert = UIAlertController(title: "Instant JSON", message: jsonString, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

class InstantJSONDocumentExample: Example {
    override init() {
        super.init()

        title = "Instant JSON - Document"
        contentDescription = "Generate and apply Instant JSON for a document."
        category = .annotations
        priority = 301
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)

        let annotation = InkAnnotation()

        // Add an ink annotation.
        let lines = [
            [CGPoint(x: 100, y: 100), CGPoint(x: 100, y: 200), CGPoint(x: 150, y: 300)],     // first line
            [CGPoint(x: 200, y: 100), CGPoint(x: 200, y: 200), CGPoint(x: 250, y: 300)]
        ]

        let pageInfo = document.pageInfoForPage(at: 0)!
        annotation.lineWidth = 5
        annotation.lines = ConvertToPDFLines(viewLines: lines, pageInfo: pageInfo, viewBounds: UIScreen.main.bounds)
        annotation.color = UIColor(red: 0.667, green: 0.279, blue: 0.748, alpha: 1)
        annotation.pageIndex = 0
        document.add(annotations: [annotation])

        let controller = InstantJSONDocumentPDFController(document: document)
        let exportButton = UIBarButtonItem(title: "Export Instant JSON", style: .plain, target: controller, action: #selector(InstantJSONDocumentPDFController.exportInstantJSON(_:)))
        controller.navigationItem.rightBarButtonItems = [exportButton]
        return controller
    }

    // MARK: Controller

    class InstantJSONDocumentPDFController: PDFViewController {

        // MARK: Actions

        @objc func exportInstantJSON(_ sender: AnyObject) {

            // Generate Instant JSON for the original document.
            // The data is generally stored stored in an external file in order to be retrieved later when reloading the document.
            let data = withFirstProvider(of: self.document!) {
                return try! self.document!.generateInstantJSON(from: $0)
            }

            // Reload the document
            let reloadedDocument = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)

            // Display the original reloaded document without instant JSON
            reloadedDocument.title = "Reloaded Document without Instant JSON"
            self.document = reloadedDocument

            // Apply the Instant JSON data after two seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                let jsonContainer = DataContainerProvider(data: data)
                withFirstProvider(of: reloadedDocument) {
                    try! reloadedDocument.applyInstantJSON(fromDataProvider: jsonContainer, to: $0, lenient: false)
                }

                // And reload data.
                reloadedDocument.title = "Reloaded Document with Instant JSON"
                self.reloadData()
            }
        }
    }

    class InstantJSONAttachmentExample: Example {
        override init() {
            super.init()

            title = "Instant JSON - Attachment"
            contentDescription = "Write and attach Instant JSON binary data for a vector stamp annotation."
            category = .annotations
            priority = 302
        }

        override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
            let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)

            let logoURL = AssetLoader.assetURL(for: "PSPDFKit Logo.pdf")
            let vectorStamp = StampAnnotation()
            vectorStamp.boundingBox = CGRect(x: 50, y: 724, width: 200, height: 200)
            vectorStamp.appearanceStreamGenerator = FileAppearanceStreamGenerator(fileURL: logoURL)
            document.add(annotations: [vectorStamp])

            let controller = InstantJSONAttachmentPDFController(document: document)
            let exportButton = UIBarButtonItem(title: "Export Instant JSON Attachment", style: .plain, target: controller, action: #selector(InstantJSONAttachmentPDFController.exportInstantJSON(_:)))
            controller.navigationItem.rightBarButtonItems = [exportButton]
            return controller
        }

        // MARK: Controller

        class InstantJSONAttachmentPDFController: PDFViewController {

            // MARK: Actions

            @objc func exportInstantJSON(_ sender: AnyObject) {

                // The document's first stamp annotation on the first page.
                let stampAnnotation = self.document!.annotationsForPage(at: 0, type: .stamp).first!

                // Generate Instant JSON data for the stamp annotation.
                let jsonData = try! stampAnnotation.generateInstantJSON()

                // Write the binary to the data sink.
                // In a production environment, you need to persist the data sink's data (dataSink.data) in an external file so you can retrieve and attach it later when reloading the document.
                let dataSink = DataContainerSink(data: nil)
                if stampAnnotation.hasBinaryInstantJSONAttachment {
                    try! stampAnnotation.writeBinaryInstantJSONAttachment(to: dataSink)
                }

                // Reload the document
                let reloadedDocument = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: true)

                // Display the original reloaded document without instant JSON
                reloadedDocument.title = "Reloaded Document without Instant JSON"
                self.document = reloadedDocument

                // Apply the Instant JSON data after two seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self = self else { return }
                    let attachmentData = DataContainerProvider(data: dataSink.data)
                    let annotation = withFirstProvider(of: reloadedDocument) {
                        // Create annotation from Instant JSON data.
                        return try! Annotation(fromInstantJSON: jsonData, documentProvider: $0)
                    }

                    // Attach the attachment data.
                    try! annotation.attachBinaryInstantJSONAttachment(fromDataProvider: attachmentData)

                    // Add the annotation to the document.
                    reloadedDocument.add(annotations: [annotation])

                    // And reload data.
                    reloadedDocument.title = "Reloaded Document with Instant JSON"
                    self.reloadData()
                }
            }
        }
    }
}
