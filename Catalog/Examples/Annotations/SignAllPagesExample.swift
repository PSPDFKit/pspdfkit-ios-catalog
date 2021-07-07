//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

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
        signatureController.configuration.availableModes = [.draw]
        signatureController.delegate = self

        baseViewController.present(signatureController, animated: true)
    }
}

extension SignAllPagesExample: SignatureCreationViewControllerDelegate {

    func signatureCreationViewControllerDidFinish(_ signatureController: SignatureCreationViewController) {
        guard let navigationController = signatureController.presentingViewController as? UINavigationController else {
            return
        }

        signatureController.dismiss(animated: true) {
            // Create the document.
            let document = AssetLoader.document(for: .JKHF)
            document.annotationSaveMode = .disabled

            // We want to add the signature at the bottom of the page.
            for pageIndex in 0..<document.pageCount {
                // Check if we have already signed and ignore if so.
                let alreadySigned = document.annotations(at: pageIndex, type: InkAnnotation.self).contains { inkAnnotation in
                    return inkAnnotation.isSignature
                }
                // Not yet signed -> create new annotation.
                if !alreadySigned {
                    self.addAnnotation(from: signatureController, onDocument: document, pageIndex: pageIndex)
                }
            }

            // Now we could flatten the PDF so that the signature is "burned in".
            let flattenAlert = UIAlertController(title: "Flatten Annotations", message: "Flattening will merge the annotations with the page content", preferredStyle: .alert)
            flattenAlert.addAction(UIAlertAction(title: "Flatten", style: .destructive, handler: { _ in
                let tempURL = TemporaryPDFFileURL(prefix: "flattened_signature")
                self.status = StatusHUDItem.progress(withText: localizedString("Preparing") + "…")
                self.status?.push(animated: true, on: navigationController.view.window)
                // Perform in background to allow progress showing.
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
        let margin: CGFloat = 10.0
        let maxSize = CGSize(width: 150.0, height: 75.0)

        // Prepare the lines and convert them from view space to PDF space. (PDF space is mirrored!)
        guard let pageInfo = document.pageInfoForPage(at: pageIndex) else {
            return
        }

        let valueLines = signatureController.drawView.pointSequences.map { $0.map({ NSValue.valueWithDrawingPoint($0) }) }

        let lines = ConvertViewLines(pdfLines: valueLines, pageInfo: pageInfo, viewBounds: CGRect(origin: .zero, size: pageInfo.size))

        // Calculate the size, aspect ratio correct.
        let lineWidth = signatureController.drawView.lineWidth
        let annotationSize = BoundingBoxFromLines(lines, lineWidth: lineWidth).size

        let scale: CGFloat = {
            let xScale = maxSize.width / annotationSize.width
            let yScale = maxSize.height / annotationSize.height
            let minScale = min(xScale, yScale)
            return minScale > 1.0 ? 1.0 : minScale
        }()
        let scaledAnnotationSize = CGSize(width: round(annotationSize.width * scale), height: round(annotationSize.height * scale))

        // Create the annotation.
        let annotation = InkAnnotation(lines: lines.map { $0.map({ $0.drawingPointValue }) })
        annotation.isSignature = true
        annotation.lineWidth = lineWidth
        // Add lines to bottom right. (PDF zero is bottom left)
        annotation.boundingBox = CGRect(x: pageInfo.size.width - scaledAnnotationSize.width - margin, y: margin, width: scaledAnnotationSize.width, height: scaledAnnotationSize.height)
        annotation.color = signatureController.drawView.strokeColor
        annotation.naturalDrawingEnabled = signatureController.configuration.isNaturalDrawingEnabled
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
