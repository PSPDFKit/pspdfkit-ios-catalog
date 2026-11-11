//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

struct StreamingDocumentDefinition: Codable {
    /// The name of the document (MyDocument.pdf)
    let name: String
    /// The remote URL of the document, where the individual chunks are accessible
    let url: URL
    /// The number of chunks. Each chunk corresponds to a number of pages.
    let chunks: [Int]
    /// Page sizes for each page.
    let pageSizes: [CGSize]
    /// Annotations that are sent in addition to the existing PDF annotations.
    /// This only supports basic annotations (highlight, ink, freeText) and does not support PDF Forms.
    let annotations: AnnotationContainer

    /// Calculate chunks for a specific page size
    static func chunks(pages: Int, chunkSize: Int = 1) -> [Int] {
        var pagesLeft = pages
        var chunks = [Int]()
        while pagesLeft > 0 {
            if pagesLeft >= chunkSize {
                chunks.append(chunkSize)
                pagesLeft -= chunkSize
            } else {
                chunks.append(pagesLeft)
                break
            }
        }
        return chunks
    }

    /// Returns range of pages that are represented by the specific chunk. (can be 1 or multiple)
    func pagesFor(chunkIndex: Int) -> Range<Int> {
        var startPage = 0
        for index in 0..<chunkIndex {
            startPage += chunks[index]
        }
        return startPage ..< startPage + chunks[chunkIndex]
    }

    /// Translates pages to chunks. (This can be a 1:1 relationship but doesn't have to be
    func chunkIndex(for pageIndex: PageIndex) -> Int {
        var startPage = 0
        var chunkIndex = 0
        while startPage < pageIndex {
            startPage += chunks[chunkIndex]
            chunkIndex += 1
        }
        return chunkIndex
    }

    /// Return URL for a downloadable thumbnail image.
    func thumbnailURL(for pageIndex: PageIndex) -> URL {
        let fileName = name.replacingOccurrences(of: ".pdf", with: "")
        let escapedName = "\(fileName)_\(pageIndex).jpg".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return URL(string: "\(url)/\(escapedName)")!
    }

    /// Builds the download URL from the host, document name and chunk.
    func documentURL(chunkIndex: Int) -> URL {
        let fileName = name.replacingOccurrences(of: ".pdf", with: "")
        let escapedName = "\(fileName)_\(chunkIndex).pdf".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return URL(string: "\(url)/\(escapedName)")!
    }

    /// Converts remote URL to local URL.
    func localURLFrom(remoteUrl: URL) -> URL {
        downloadFolder.appendingPathComponent(remoteUrl.lastPathComponent)
    }

    /// Helper that tests if the URL has been cached.
    func fileIsCached(pageIndex: PageIndex) -> Bool {
        let url = documentURL(chunkIndex: chunkIndex(for: pageIndex))
        return FileManager.default.fileExists(atPath: localURLFrom(remoteUrl: url).path)
    }

    /// Helper to define where this document will be stored.
    /// The scheme is AppData/Documents/DocumentName
    var downloadFolder: URL {
        let documentFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentFolderURL.appendingPathComponent(name.replacingOccurrences(of: ".pdf", with: ""))
    }
}

/// Container to use codable serialization on Annotation
public struct AnnotationContainer: Codable {
    let annotations: [Annotation]

    private enum CodingKeys: String, CodingKey {
        case annotationsData
    }

    public init(annotations: [Annotation]) {
        self.annotations = annotations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let annotationsData = try container.decode(Data.self, forKey: .annotationsData)
        // This needs an ugly cast beceause NSArray syntax is not directly convertible
        annotations = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, Annotation.self], from: annotationsData) as? [Annotation] ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let annotationsData = try NSKeyedArchiver.archivedData(withRootObject: annotations, requiringSecureCoding: true)
        try container.encode(annotationsData, forKey: .annotationsData)
    }
}
