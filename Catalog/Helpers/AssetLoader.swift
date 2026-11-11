//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

@objc(PSCAssetLoader)
class AssetLoader: NSObject {

    @objc(assetURLWithName:)
    class func assetURL(for name: AssetName) -> URL {
        let bundle = Bundle(for: AssetLoader.self)
        let nameString = name.rawValue as NSString
        let assetURL = bundle.url(forResource: nameString.deletingPathExtension, withExtension: nameString.pathExtension, subdirectory: "Samples")
        precondition(assetURL != nil, "The resource must exist.")
        return assetURL!
    }

    /// Load sample file with file `name`.
    @objc(documentWithName:)
    class func document(for name: AssetName) -> Document {
        return Document(url: self.assetURL(for: name))
    }

    /// Loads a document and copies it to a temp directory so it can be written.
    @objc(writableDocumentWithName:overrideIfExists:)
    class func writableDocument(for name: AssetName, overrideIfExists: Bool) -> Document {
        let anURL = self.assetURL(for: name)
        let writableURL = FileHelper.copyFileURLToDocumentDirectory(anURL, overwrite: overrideIfExists)
        let document = Document(url: writableURL)
        document.annotationSaveMode = .embedded
        return document
    }

    /// Generates a test PDF with `title` as content and title.
    @objc(temporaryDocumentWithString:)
    class func temporaryDocument(with title: String) -> Document {
        let pdfData = UIGraphicsPDFRenderer(bounds: CGRect(x: 0.0, y: 0.0, width: 210.0 * 3, height: 297.0 * 3),
                              format: UIGraphicsPDFRendererFormat())
            .pdfData {
                $0.beginPage()
                title.draw(at: CGPoint(x: 20.0, y: 20.0), withAttributes: nil)
            }
        let dataProvider = DataContainerProvider(data: pdfData)
        let document = Document(dataProviders: [dataProvider])
        document.title = title
        return document
    }

}
