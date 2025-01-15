//
//  Copyright © 2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class InstantJSONSignatureStoreExample: Example {

    override init() {
        super.init()

        title = "Instant JSON Signature Store"
        contentDescription = "Save electronic signatures in a single JSON file."
        category = .annotations
        priority = 310
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: "Form.pdf", overrideIfExists: false)

        let controller = PDFViewController(document: document) {
            let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let signatureStoreDirectoryURL = documentsDirectoryURL.appendingPathComponent("InstantJSONSignatureStore", isDirectory: true)
            $0.signatureStore = InstantJSONSignatureStore(directoryURL: signatureStoreDirectoryURL)
        }

        controller.navigationItem.setRightBarButtonItems([controller.signatureButtonItem], for: .document, animated: false)

        return controller
    }
}

// MARK: -

/// Stores signature annotations in a JSON file.
///
/// The top-level object of the file will have an entry “signatures” containing an array annotations in the Instant JSON format.
/// https://www.nutrient.io/guides/ios/json/
@objc(PSCInstantJSONSignatureStore) private class InstantJSONSignatureStore: NSObject, SignatureStore {
    private static let directoryURLKey = "directoryURL"
    private static let rootJSONKey = "signatures"

    let directoryURL: URL

    /// Creates a 1x1 blank PDF document in memory.
    ///
    /// Setting Instant JSON binary attachments requires that the annotation is added to a document.
    ///
    /// Even for annotations without attachments, Instant JSON (de)serialization requires a document because the
    /// coordinate space used by Annotation matches the PDF spec by putting the origin in the bottom-left corner of the
    /// page with y increasing upwards. However Instant JSON places the coordinate space in the top-left corner of the
    /// page with y increasing downwards. Therefore, Nutrient needs to know the page height in order to preserve the
    /// annotation’s position on the page.
    ///
    /// Using this document means the origin of the annotation bounding boxes is essentially undefined in the JSON.
    /// However this is fine for a signature store because the signature annotations have no intrinsic location and
    /// the origin of the bounding box will always be set when adding a saved signature to a document.
    private let placeholderDocument: Document = {
        let pdfData = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 1, height: 1)).pdfData { $0.beginPage() }
        return Document(dataProviders: [DataContainerProvider(data: pdfData)])
    }()

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    private var jsonFileURL: URL {
        directoryURL.appendingPathComponent("signatures.json", isDirectory: false)
    }

    // MARK: - NSSecureCoding

    static var supportsSecureCoding: Bool {
        true
    }

    func encode(with coder: NSCoder) {
        coder.encode(directoryURL as NSURL, forKey: Self.directoryURLKey)
    }

    required init?(coder: NSCoder) {
        guard let url = coder.decodeObject(of: NSURL.self, forKey: Self.directoryURLKey) else {
            return nil
        }
        self.directoryURL = url as URL
    }

    // MARK: - SignatureStore

    func addSignature(_ signature: SignatureContainer) {
        guard placeholderDocument.add(annotations: [signature.signatureAnnotation]) else {
            print("InstantJSONSignatureStore: Couldn’t add annotation to placeholder document.")
            return
        }

        var signatures = self.signatures!
        signatures.append(signature)
        self.signatures = signatures
    }

    func removeSignature(_ signature: SignatureContainer) -> Bool {
        var signatures = self.signatures!
        guard let index = signatures.firstIndex(of: signature) else {
            return false
        }

        guard placeholderDocument.remove(annotations: [signature.signatureAnnotation]) else {
            print("InstantJSONSignatureStore: Couldn’t remove annotation from placeholder document.")
            return false
        }

        signatures.remove(at: index)
        self.signatures = signatures

        return true
    }

    lazy var signatures: [SignatureContainer]? = loadSignatures() {
        didSet {
            saveSignatures()
        }
    }

    // MARK: - Private support for SignatureStore

    private func loadSignatures() -> [SignatureContainer] {
        let combinedData: Data
        do {
            combinedData = try Data(contentsOf: jsonFileURL)
        } catch {
            return []
        }

        let combinedDictionary: [String: [NSDictionary]]
        do {
            guard let combinedDict = try JSONSerialization.jsonObject(with: combinedData) as? [String: [NSDictionary]] else {
                print("InstantJSONSignatureStore: Couldn’t read JSON because it doesn’t have the shape [String: [NSDictionary]].")
                return []
            }
            combinedDictionary = combinedDict
        } catch {
            print("InstantJSONSignatureStore: Couldn’t read JSON: \(error)")
            return []
        }

        guard let annotationJSONDictionaries = combinedDictionary[Self.rootJSONKey] else {
            print("InstantJSONSignatureStore: Couldn’t read JSON because top-level key “\(Self.rootJSONKey)” is missing.")
            return []
        }

        let annotations: [Annotation] = annotationJSONDictionaries.compactMap {
            do {
                let annotationJSONData = try JSONSerialization.data(withJSONObject: $0)

                guard $0["type"] as? String == "pspdfkit/image" else {
                    // No attachment needed.
                    return try placeholderDocument.documentProviders[0].addAnnotation(fromInstantJSON: annotationJSONData)
                }

                guard let attachmentIdentifier = $0["imageAttachmentId"] as? String else {
                    print("InstantJSONSignatureStore: Couldn’t attach image data because the annotation has no imageAttachmentId.")
                    return nil
                }

                let attachmentDataProvider = FileDataProvider(fileURL: directoryURL.appendingPathComponent(attachmentIdentifier, isDirectory: false))
                return try placeholderDocument.documentProviders[0].addAnnotation(fromInstantJSON: annotationJSONData, attachmentDataProvider: attachmentDataProvider)
            } catch {
                print("InstantJSONSignatureStore: Couldn’t create Annotation from JSON: \(error)")
                return nil
            }
        }

        return annotations.map { SignatureContainer(signatureAnnotation: $0, signer: nil, biometricProperties: nil) }
    }

    private func saveSignatures() {
        guard let signatures else {
            do {
                try FileManager.default.removeItem(at: directoryURL)
            } catch {
                print("InstantJSONSignatureStore: Couldn’t remove directory: \(error)")
            }
            return
        }

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            print("InstantJSONSignatureStore: Couldn’t create directory: \(error)")
            return
        }

        // Remove old files. All attachments will all be regenerated. The imageAttachmentId is different each time.
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [])
            for url in urls {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("InstantJSONSignatureStore: Couldn’t remove file: \(error)")
            return
        }

        let annotations = signatures.map { $0.signatureAnnotation }

        precondition(placeholderDocument.annotations(at: 0).count == annotations.count, "Annotations aren’t in sync with placeholder document: \(placeholderDocument.annotations(at: 0))")

        let annotationJSONDictionaries: [NSDictionary] = annotations.compactMap {
            do {
                let annotationJSONData = try $0.generateInstantJSON()
                let jsonObject = try JSONSerialization.jsonObject(with: annotationJSONData)

                if let jsonDictionary = jsonObject as? NSDictionary {
                    if jsonDictionary["type"] as? String == "pspdfkit/image" {
                        guard let attachmentIdentifier = jsonDictionary["imageAttachmentId"] as? String else {
                            print("InstantJSONSignatureStore: Couldn’t write image attachment because the annotation has no imageAttachmentId.")
                            return nil
                        }

                        let attachmentFileURL = directoryURL.appendingPathComponent(attachmentIdentifier, isDirectory: false)
                        let dataSink = try FileDataSink(fileURL: attachmentFileURL)
                        try $0.writeBinaryInstantJSONAttachment(to: dataSink)
                    }
                    return jsonDictionary
                } else {
                    print("InstantJSONSignatureStore: Couldn’t write JSON because the Instant JSON is not a dictionary.")
                    return nil
                }
            } catch {
                print("InstantJSONSignatureStore: Couldn’t generate Instant JSON: \(error)")
                return nil
            }
        }

        let combinedDictionary: [String: [NSDictionary]] = [Self.rootJSONKey: annotationJSONDictionaries]
        do {
            let combinedData = try JSONSerialization.data(withJSONObject: combinedDictionary, options: [.prettyPrinted, .sortedKeys])
            try combinedData.write(to: jsonFileURL)
        } catch {
            print("InstantJSONSignatureStore: Couldn’t write JSON: \(error)")
        }
    }
}
