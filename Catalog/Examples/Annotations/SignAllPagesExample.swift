//
//  Copyright 2025 Nutrient. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class SignAllPagesExample: Example {
    var status: StatusHUDItem?

    override init() {
        super.init()
        title = "Sign All Pages"
        contentDescription = "Will add a signature to all pages of a document, optionally flattened."
        category = .annotations
        priority = 200
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        guard let baseViewController = delegate?.currentViewController else {
            return nil
        }

        // Ask for the annotation username, if needed.
        if !UsernameHelper.isDefaultAnnotationUserNameSet {
            // We don't use the static helper here because we do not yet have a PDFViewController at this point.
            let helper = UsernameHelper()
            helper.ask(forDefaultAnnotationUsername: baseViewController, suggestedName: nil) { _ in
                self.showSignatureUI(on: baseViewController)
            }
        } else {
            showSignatureUI(on: baseViewController)
        }

        return nil
    }

    func showSignatureUI(on baseViewController: UIViewController) {
        // Show the signature controller
        let signatureController = SignatureCreationViewController()
        signatureController.delegate = self

        baseViewController.present(signatureController, animated: true)
    }
}

extension SignAllPagesExample: SignatureCreationViewControllerDelegate {

    func signatureCreationViewControllerDidFinish(_ signatureController: SignatureCreationViewController) {
        guard let navigationController = signatureController.presentingViewController as? UINavigationController else {
            return
        }

        // Create the document.
        let document = AssetLoader.writableDocument(for: .annualReport, overrideIfExists: true)

        // We want to add the signature at the bottom of the page.
        for pageIndex in 0..<document.pageCount {
            // Check if we have already signed and ignore if so.
            let alreadySigned = document.annotationsForPage(at: pageIndex, type: [.ink, .stamp]).contains { annotation in
                if let ink = annotation as? InkAnnotation {
                    return ink.isSignature
                } else if let stamp = annotation as? StampAnnotation {
                    return stamp.isSignature
                } else {
                    return false
                }
            }
            // Not yet signed -> create new annotation.
            if !alreadySigned {
                self.addAnnotation(from: signatureController, onDocument: document, pageIndex: pageIndex)
            }
        }

        // The signature creation view needs to be at the correct size when extracting the
        // signature annotations, so don’t dismiss it until after creating the annotations.
        signatureController.dismiss(animated: true) {
            // Now we could flatten the PDF so that the signature is "burned in".
            let flattenAlert = UIAlertController(title: "Flatten Annotations", message: "Flattening will merge the annotations with the page content", preferredStyle: .alert)
            flattenAlert.addAction(UIAlertAction(title: "Flatten", style: .destructive, handler: { _ in
                let tempURL = FileHelper.temporaryPDFFileURL(prefix: "flattened_signature")
                self.status = StatusHUDItem.progress(withText: localizedString("Preparing") + "…")
                self.status?.push(animated: true, on: navigationController.view.window)
                // Flatten in the background so progress can be shown.
                DispatchQueue.global(qos: .default).async {
                    let configuration = Processor.Configuration(document: document)!
                    configuration.modifyAnnotations(ofTypes: .all, change: .flatten)
                    let processor = Processor(configuration: configuration, securityOptions: nil)
                    processor.delegate = self
                    try? processor.write(toFileURL: tempURL)

                    DispatchQueue.main.async {
                        self.status?.pop(animated: true)
                        self.status = nil
                        let flattenedDocument = Document(url: tempURL)
                        let pdfController = PDFViewController(document: flattenedDocument)
                        navigationController.pushViewController(pdfController, animated: true)
                    }
                }
            }))
            flattenAlert.addAction(UIAlertAction(title: "Allow Editing", style: .default, handler: { _ in
                let pdfController = PDFViewController(document: document)
                navigationController.pushViewController(pdfController, animated: true)
            }))
            navigationController.present(flattenAlert, animated: true)
        }
    }

    func signatureCreationViewControllerDidCancel(_ signatureController: SignatureCreationViewController) {
        signatureController.dismiss(animated: true)
    }

    func addAnnotation(from signatureController: SignatureCreationViewController, onDocument document: Document, pageIndex: PageIndex) {
        guard let pageInfo = document.pageInfoForPage(at: pageIndex),
              let annotation = signatureController.signatureAnnotation(forPageWith: pageInfo.size) else {
            return
        }

        let margin: CGFloat = 10.0
        let maxSize = CGSize(width: 150.0, height: 75.0)

        // Calculate the size, aspect ratio correct.
        let annotationSize = annotation.boundingBox.size

        let scale: CGFloat = {
            let xScale = maxSize.width / annotationSize.width
            let yScale = maxSize.height / annotationSize.height
            let minScale = min(xScale, yScale)
            return minScale > 1.0 ? 1.0 : minScale
        }()
        let scaledAnnotationSize = CGSize(width: round(annotationSize.width * scale), height: round(annotationSize.height * scale))

        // Create the annotation.
        // Add annotation to bottom right adding additional padding to avoid signature overlapping
        // the page number in the PDF. (PDF zero is bottom left)
        let pageLabelPadding: CGFloat = 40
        annotation.boundingBox = CGRect(x: pageInfo.size.width - scaledAnnotationSize.width - margin, y: margin + pageLabelPadding, width: scaledAnnotationSize.width, height: scaledAnnotationSize.height)
        annotation.contents = "Signed on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)) by test user."
        annotation.pageIndex = pageIndex

        // Add annotation.
        document.add(annotations: [annotation])
    }
}

extension SignAllPagesExample: ProcessorDelegate {
    func processor(_ processor: Processor, didProcessPage currentPage: UInt, totalPages: UInt) {
        status?.progress = CGFloat(currentPage + 1) / CGFloat(totalPages)
    }
}
