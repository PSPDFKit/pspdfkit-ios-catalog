//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

extension URL {
    /// Copies a file to the documents directory.
    func copyToDocumentDirectory(overwrite: Bool = false) -> URL {
        return FileHelper.copyFileURLToDocumentDirectory(self, overwrite: overwrite)
    }

    /// Detects if the file is located in the app's Samples directory.
    var isLocatedInSamplesFolder: Bool {
        let samplesURL = Bundle.main.resourceURL!.appendingPathComponent("Samples")
        // We need to resolve symlinks using `resolvingSymlinksInPath` to strip the private designator in the start of the URL.
        return self.resolvingSymlinksInPath().path.hasPrefix(samplesURL.resolvingSymlinksInPath().path)
    }

    /// Detects if the file is located in the app's Documents/Inbox directory.
    var isLocatedInInbox: Bool {
        let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let inboxPath = docsFolder.appendingPathComponent("Inbox").path
        // We need to resolve symlinks using `resolvingSymlinksInPath` to strip the private designator in the start of the URL.
        return self.resolvingSymlinksInPath().path.hasPrefix(inboxPath)
    }
}
