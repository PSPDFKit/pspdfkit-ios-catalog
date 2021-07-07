//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// Creates a temporary file URL.
func TemporaryFileURL(prefix: String?, pathExtension: String) -> URL {
    let sanePathExtension = pathExtension.hasPrefix(".") ? pathExtension : ".\(pathExtension)"
    let uuidString = prefix != nil ? NSUUID().uuidString : "_\(NSUUID().uuidString)"

    let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let tempURL = tempDirectory.appendingPathComponent("\(prefix ?? "")\(uuidString)\(sanePathExtension)", isDirectory: false)
    return tempURL
}

/// Creates a temporary PDF file URL.
func TemporaryPDFFileURL(prefix: String? = nil) -> URL {
    return TemporaryFileURL(prefix: prefix, pathExtension: ".pdf")
}

/// Copies a file to the documents directory.
 func CopyFileURLToDocumentDirectory(_ documentURL: URL, overwrite: Bool = false) -> URL {
    // Copy file from original location to the Document directory (a location we can write to).
    let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let newURL = docsFolder.appendingPathComponent(documentURL.lastPathComponent)
    let exists = FileManager.default.fileExists(atPath: newURL.path)
    if overwrite {
        do {
            try FileManager.default.removeItem(at: newURL)
        } catch {
            print("Error while removing file at \(newURL.path): \(error.localizedDescription)")
        }
    }

    if !exists || overwrite {
        do {
            try FileManager.default.copyItem(at: documentURL, to: newURL)
        } catch {
            print("Error while copying \(documentURL.path): \(error.localizedDescription)")
        }
    }

    return newURL
 }

// Used to expose these helpers to Objective-C
@objc(PSCFileHelper)
public class FileHelper: NSObject {
    @objc public class func temporaryFileURL(prefix: String?, pathExtension: String) -> URL {
        return TemporaryFileURL(prefix: prefix, pathExtension: pathExtension)
    }

    @objc public class func copyFileURLToDocumentDirectory(_ documentURL: URL, overwrite: Bool) -> URL {
        return CopyFileURLToDocumentDirectory(documentURL, overwrite: overwrite)
    }
}
