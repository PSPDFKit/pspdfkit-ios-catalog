//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PSCComparisonExample.m' for the Objective-C version of this example.

class ComparisonExample: Example {

    override init() {
        super.init()
        title = "Document Comparison"
        contentDescription = "Compare PDFs by using a different stroke color for each document."
        category = .componentsExamples
        priority = 3
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let firstDocument = AssetLoader.document(for: AssetName(rawValue: "FloorPlan_1.pdf"))
        let secondDocument = AssetLoader.document(for: AssetName(rawValue: "FloorPlan_2.pdf"))

        let tabbedController = PDFTabbedViewController()
        tabbedController.documents = try! generateComparisonDocuments(byMerging: firstDocument, with: secondDocument)
        tabbedController.setVisibleDocument(tabbedController.documents[2], scrollToPosition: false, animated: false)
        return tabbedController
    }

    func generateComparisonDocuments(byMerging firstDocument: Document, with secondDocument: Document) throws -> [Document] {
        let greenDocument = try! self.createNewPDF(from: firstDocument, withStrokeColor: .green, fileName: "Old.pdf")
        let redDocument = try! self.createNewPDF(from: secondDocument, withStrokeColor: .red, fileName: "New.pdf")

        let configuration = Processor.Configuration(document: greenDocument)!
        configuration.mergeAutoRotatedPage(from: redDocument, password: nil, sourcePageIndex: 0, destinationPageIndex: 0, transform: .identity, blendMode: .darken)

        let processor = Processor(configuration: configuration, securityOptions: nil)
        let mergedDocumentURL = ComparisonExample.temporaryURL(with: "Comparison.pdf")
        // The processor doesn't overwrite files. Files might not yet exist on first run.
        do { try FileManager.default.removeItem(at: mergedDocumentURL) } catch CocoaError.fileNoSuchFile { }
        try! processor.write(toFileURL: mergedDocumentURL)

        let mergedDocument = Document(url: mergedDocumentURL)
        return [greenDocument, redDocument, mergedDocument]
    }

    func createNewPDF(from document: Document, withStrokeColor strokeColor: UIColor, fileName: String) throws -> Document {
        let configuration = Processor.Configuration(document: document)!
        configuration.changeStrokeColorOnPage(at: 0, to: strokeColor)

        let processor = Processor(configuration: configuration, securityOptions: nil)
        let destinationURL = ComparisonExample.temporaryURL(with: fileName)

        // The processor doesn't overwrite files. Files might not yet exist on first run.
        do { try FileManager.default.removeItem(at: destinationURL) } catch CocoaError.fileNoSuchFile { }
        try processor.write(toFileURL: destinationURL)
        return Document(url: destinationURL)
    }

    class func temporaryURL(with name: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
    }
}
