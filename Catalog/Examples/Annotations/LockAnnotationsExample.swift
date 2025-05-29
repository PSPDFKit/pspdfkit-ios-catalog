//
//  Copyright © 2017-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class LockAnnotationsExample: Example {

    override init() {
        super.init()

        title = "Generate a new file with locked annotations"
        contentDescription = "Uses the annotation flags to create a locked copy."
        category = .annotations
        priority = 1000
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let samplesURL = Bundle.main.resourceURL!.appendingPathComponent("Samples")
        let documentURL = samplesURL.appendingPathComponent(AssetName.annualReport.rawValue)
        let writableDocumentURL = documentURL.copyToDocumentDirectory()

        // Copy the document to the temp directory.
        let tempURL = FileHelper.temporaryPDFFileURL(prefix: "locked_\(writableDocumentURL.lastPathComponent)")
        if FileManager.default.fileExists(atPath: writableDocumentURL.path) {
            try? FileManager.default.copyItem(at: writableDocumentURL, to: tempURL)
        } else {
            try? FileManager.default.copyItem(at: documentURL, to: tempURL)
        }

        // Open the new file and modify the annotations to be locked.
        let document = Document(url: tempURL)
        document.annotationSaveMode = .embedded

        // Create at least one annotation if the document is currently empty.
        let allTypesButLinks = Annotation.Kind.all.subtracting(.link)
        let allAnnotations = document.annotationsForPage(at: 0, type: allTypesButLinks)
        if allAnnotations.isEmpty {
            let ink = InkAnnotation.sampleInkAnnotation(in: CGRect(x: 100.0, y: 100.0, width: 200.0, height: 200.0))
            ink.color = UIColor(red: 0.667, green: 0.279, blue: 0.748, alpha: 1.0)
            ink.pageIndex = 0
            document.add(annotations: [ink])
        }

        // Lock all annotations except links and forms/widgets.
        let allTypesButLinkAndForms = Annotation.Kind.all.subtracting([.link, .widget])
        for pageIndex in 0..<document.pageCount {
            let annotations = document.annotationsForPage(at: pageIndex, type: allTypesButLinkAndForms)
            for annotation in annotations {
                // Preserve existing flags, just set the locked and locked contents flags.
                annotation.flags.update(with: [.locked, .lockedContents])
            }
        }

        // Save the document.
        try? document.save()

        print("Locked file: \(tempURL.path)")

        let controller = PDFViewController(document: document)
        return controller
    }
}
