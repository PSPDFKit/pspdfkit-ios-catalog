//
//  Copyright © 2022-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class DetachedSignatureCreationExample: Example {

    var presentingController: UIViewController?

    override init() {
        super.init()
        title = "Detached Signature Creation"
        contentDescription = "Shows how to present the Signature Creation UI flow independently to store the signature."
        category = .annotations
        priority = 200
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController? {
        guard let baseViewController = delegate?.currentViewController else {
            return nil
        }

        // Ask for the annotation username, if needed.
        if !UsernameHelper.isDefaultAnnotationUserNameSet {
            // We don't use the static helper here because we do not have a PDFViewController at this point.
            let helper = UsernameHelper()
            helper.ask(forDefaultAnnotationUsername: baseViewController, suggestedName: UsernameHelper.defaultAnnotationUsername) { _ in
                self.showSignatureUI(on: baseViewController)
            }
        } else {
            showSignatureUI(on: baseViewController)
        }

        return nil
    }

    /// Presents a list of saved signatures in the system keychain using `KeychainSignatureStore`.
    /// Signature Creation UI is presented if no signature is available.
    /// - Parameter baseViewController: Controller that is supposed to present the relevant Signature UI.
    func showSignatureUI(on baseViewController: UIViewController) {
        let controllerToPresent: UIViewController

        // We are using the default system keychain signature store to check for stored signatures.
        // You can also use your signature store by implementing the `SignatureStore` protocol.
        // See https://www.nutrient.io/api/ios/documentation/pspdfkitui/signaturestore/
        //
        // Please reuse the signature store instance created at this point until
        // signature has been added to the signature store / document.
        // We have not done that in this example for the sake of simplicity.
        let keychainStore = KeychainSignatureStore()

        // Show stored signatures if the KeychainStore has saved signatures available.
        if !keychainStore.signatures.isEmpty {
            let signatureSelectorController = SignatureSelectorViewController()
            signatureSelectorController.delegate = self
            signatureSelectorController.signatureStore = keychainStore
            let navVC = UINavigationController(rootViewController: signatureSelectorController)
            controllerToPresent = navVC
        } else {
            let signatureController = createSignatureCreationUI()
            controllerToPresent = signatureController
        }

        baseViewController.present(controllerToPresent, animated: true)
        presentingController = baseViewController
    }

    /// Creates and sets up the UI for creating a signature.
    /// - Returns: A new signature creation controller.
    func createSignatureCreationUI() -> SignatureCreationViewController {
        let signatureController = SignatureCreationViewController()
        signatureController.delegate = self

        // Enable showing the Store Signature toggle.
        signatureController.showSaveToggle = true

        return signatureController
    }

    /// Adds the signature annotation to the bottom right of the given page in the document.
    /// The bounding box of the signature is adjusted with a max size of (150, 75) preserving the aspect ratio.
    func addSignature(_ signature: Annotation, to document: Document, at pageIndex: PageIndex) {
        guard let pageInfo = document.pageInfoForPage(at: pageIndex) else {
            return
        }

        let margin: CGFloat = 10.0
        let maxSize = CGSize(width: 150.0, height: 75.0)

        // Calculate the size, aspect ratio correct.
        let annotationSize = signature.boundingBox.size

        let scale: CGFloat = {
            let xScale = maxSize.width / annotationSize.width
            let yScale = maxSize.height / annotationSize.height
            let minScale = min(xScale, yScale)
            return minScale > 1.0 ? 1.0 : minScale
        }()
        let scaledAnnotationSize = CGSize(width: round(annotationSize.width * scale), height: round(annotationSize.height * scale))

        // Add annotation to bottom right adding additional padding to avoid signature overlapping
        // the page number in the PDF. (PDF zero is bottom left)
        let pageLabelPadding: CGFloat = 40
        signature.boundingBox = CGRect(x: pageInfo.size.width - scaledAnnotationSize.width - margin, y: margin + pageLabelPadding, width: scaledAnnotationSize.width, height: scaledAnnotationSize.height)
        signature.contents = "Signed on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)) by test user."

        // Assign the appropriate page to the signature.
        signature.pageIndex = pageIndex

        // Add annotation.
        document.add(annotations: [signature])
    }

    func showDocument(_ document: Document) {
        // We know that the presenting controller is the `CatalogViewController`, which is in a navigation controller.
        let navigationController = presentingController?.navigationController

        // Present the document.
        let pdfController = PDFViewController(document: document)
        pdfController.navigationItem.setRightBarButtonItems([pdfController.thumbnailsButtonItem, pdfController.activityButtonItem, pdfController.outlineButtonItem, pdfController.searchButtonItem], for: .document, animated: false)
        navigationController?.pushViewController(pdfController, animated: true)
    }
}

// MARK: - SignatureSelectorViewControllerDelegate

extension DetachedSignatureCreationExample: SignatureSelectorViewControllerDelegate {

    func signatureSelectorViewController(_ signatureSelectorController: SignatureSelectorViewController, didSelectSignature signature: SignatureContainer) {

        // Use the selected Signature as per your requirement.
        let storedSignature = signature.signatureAnnotation

        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled

        for pageIndex in 0..<document.pageCount {
            // Create a distinct copy of the stored annotation by explicity creating a new annotation
            // using the initializers (Please do not use `Annotation.copy()`).
            // We know that only ink and image stamp annotations are supported.
            // You can also use your own custom subclasses for ink and stamp annotation here by
            // using your subclass initializers for the creating the signature copy below.
            if let ink = storedSignature as? InkAnnotation {
                let copy = InkAnnotation(lines: ink.lines!)
                copy.naturalDrawingEnabled = ink.naturalDrawingEnabled
                copy.lineWidth = ink.lineWidth
                if let color = ink.color {
                    copy.color = color
                    copy.alpha = color.cgColor.alpha
                }
                copy.isSignature = true
                addSignature(copy, to: document, at: pageIndex)
            } else if let stamp = storedSignature as? StampAnnotation {
                let copy = StampAnnotation(image: stamp.image)
                copy.boundingBox = CGRect(origin: .zero, size: stamp.image!.size)
                copy.isSignature = true
                addSignature(copy, to: document, at: pageIndex)
            }
        }

        // Dismiss the signature selector UI before presenting
        signatureSelectorController.dismiss(animated: true)

        // Present the signed document.
        showDocument(document)
    }

    func signatureSelectorViewControllerWillCreateNewSignature(_ signatureSelectorController: SignatureSelectorViewController) {
        // Dismiss the stored signatures list.
        signatureSelectorController.dismiss(animated: true)

        // Present the signature creation UI.
        let signatureController = createSignatureCreationUI()
        presentingController?.present(signatureController, animated: true)
    }

}

// MARK: - SignatureCreationViewControllerDelegate

extension DetachedSignatureCreationExample: SignatureCreationViewControllerDelegate {

    func signatureCreationViewControllerDidFinish(_ signatureController: SignatureCreationViewController) {
        // Access the signature created.
        // We don't have a page size available right now so we'll use an arbitrary size for the copy
        // of signature annotation that will be stored away into the signature store.
        let pageSize = CGSize(width: 500, height: 500)
        guard let originalSignature = signatureController.signatureAnnotation(forPageWith: pageSize) else {
            print("\(Swift.type(of: self)): Unable to access the created signature.")
            return
        }

        // Check if the Save Signature toggle is enabled to know whether to store the signature or not.
        if signatureController.isSaveSignatureEnabled {
            // Store the signature away in the system keychain using the `KeychainSignatureStore`.
            let container = SignatureContainer(signatureAnnotation: originalSignature, signer: nil, biometricProperties: nil)
            let signatureStore = KeychainSignatureStore()
            signatureStore.addSignature(container)
        }

        // Add the signature to all the pages of a document.
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled

        for pageIndex in 0..<document.pageCount {
            // Use the appropriate page size now that we have the page sizes available.
            guard let pageInfo = document.pageInfoForPage(at: pageIndex),
                  let signatureCopy = signatureController.signatureAnnotation(forPageWith: pageInfo.size) else {
                continue
            }
            addSignature(signatureCopy, to: document, at: pageIndex)
        }

        // The signature creation view needs to be at the correct size when extracting the
        // signature annotations, so don’t dismiss it until after creating the annotations.
        signatureController.dismiss(animated: true)

        showDocument(document)
    }

    func signatureCreationViewControllerDidCancel(_ signatureController: SignatureCreationViewController) {
        signatureController.dismiss(animated: true)
    }
}
