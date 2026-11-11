//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// Shows how to adjust the built-in signature flow without replacing its UI.
///
/// A bar button lets the user choose a stroke width and opacity once. Every signature created
/// afterwards starts with those values: `pdfViewController(_:shouldShow:options:animated:)` sets them
/// on the signing sheet's configuration right before it is shown. Once a signature is created,
/// `pdfViewController(_:placeSignature:)` lets the user decide where on the page it goes.
class SignatureAppearanceAndPlacementExample: Example {

    override init() {
        super.init()

        title = "Signature appearance and placement"
        contentDescription = "Configures stroke width and opacity for the built-in signing sheet, then asks where to place the signature."
        category = .annotations
        priority = 201
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        let controller = SignatureAppearanceAndPlacementViewController(document: document)

        // Surface the signature tool directly, so the flow is one tap away in this example.
        let signature = AnnotationToolConfiguration.ToolItem(type: .signature)
        let group = AnnotationToolConfiguration.ToolGroup(items: [signature])
        controller.annotationToolbarController?.annotationToolbar.configurations = [
            AnnotationToolConfiguration(annotationGroups: [group])
        ]
        return controller
    }
}

private class SignatureAppearanceAndPlacementViewController: PDFViewController, PDFViewControllerDelegate {

    // The appearance every new signature starts with. Persist these in your app to remember them.
    private var lineWidth: CGFloat = 3
    private var alpha: CGFloat = 1

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)
        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let appearanceItem = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), style: .plain, target: self, action: #selector(chooseAppearance))
        navigationItem.setRightBarButtonItems([appearanceItem, annotationButtonItem], for: .document, animated: false)
    }

    // MARK: - Appearance

    @objc private func chooseAppearance() {
        let alert = UIAlertController(title: "Signature appearance", message: "\n\n\n\n", preferredStyle: .alert)

        let widthLabel = UILabel(frame: CGRect(x: 20, y: 44, width: 230, height: 16))
        widthLabel.text = "Stroke width"
        widthLabel.font = .preferredFont(forTextStyle: .caption1)
        let alphaLabel = UILabel(frame: CGRect(x: 20, y: 90, width: 230, height: 16))
        alphaLabel.text = "Opacity"
        alphaLabel.font = .preferredFont(forTextStyle: .caption1)
        alert.view.addSubview(widthLabel)
        alert.view.addSubview(alphaLabel)

        let widthSlider = UISlider(frame: CGRect(x: 20, y: 60, width: 230, height: 30))
        widthSlider.minimumValue = 1
        widthSlider.maximumValue = 12
        widthSlider.value = Float(lineWidth)
        let alphaSlider = UISlider(frame: CGRect(x: 20, y: 100, width: 230, height: 30))
        alphaSlider.minimumValue = 0.1
        alphaSlider.maximumValue = 1
        alphaSlider.value = Float(alpha)
        alert.view.addSubview(widthSlider)
        alert.view.addSubview(alphaSlider)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.lineWidth = CGFloat(widthSlider.value)
            self?.alpha = CGFloat(alphaSlider.value)
        })
        present(alert, animated: true)
    }

    // MARK: - PDFViewControllerDelegate

    func pdfViewController(_ pdfController: PDFViewController, shouldShow controller: UIViewController, options: [String: Any]? = nil, animated: Bool) -> Bool {
        // The signing sheet is about to be shown: give it the chosen appearance. Return false here
        // instead to show UI of your own first, then present `controller` yourself.
        if let signatureController = controller as? SignatureCreationViewController {
            signatureController.configuration.defaultLineWidth = lineWidth
            signatureController.configuration.defaultAlpha = alpha
        }
        return true
    }

    func pdfViewController(_ pdfController: PDFViewController, placeSignature proposal: SignaturePlacementProposal) async -> AnnotationPlacement? {
        // A form field has a fixed location, so there is nothing to ask.
        guard proposal.formElement == nil, let document else { return proposal.placement }

        let proposed = proposal.placement
        let pageSize = document.pageInfoForPage(at: proposed.pageIndex)?.size ?? .zero
        let box = proposed.boundingBox
        let margin: CGFloat = 24

        // Returning nil adds nothing, which is where you would insert the signature yourself.
        return await withCheckedContinuation { continuation in
            let sheet = UIAlertController(title: "Place signature", message: nil, preferredStyle: .actionSheet)
            sheet.addAction(UIAlertAction(title: "Where it was requested", style: .default) { _ in continuation.resume(returning: proposed) })
            sheet.addAction(UIAlertAction(title: "Bottom-right of the page", style: .default) { _ in
                // PDF coordinates: the origin is bottom-left.
                continuation.resume(returning: AnnotationPlacement(pageIndex: proposed.pageIndex, boundingBox: CGRect(x: pageSize.width - box.width - margin, y: margin, width: box.width, height: box.height)))
            })
            sheet.addAction(UIAlertAction(title: "Top-left of the page", style: .default) { _ in
                continuation.resume(returning: AnnotationPlacement(pageIndex: proposed.pageIndex, boundingBox: CGRect(x: margin, y: pageSize.height - margin - box.height, width: box.width, height: box.height)))
            })
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in continuation.resume(returning: nil) })
            sheet.popoverPresentationController?.sourceView = view
            sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            present(sheet, animated: true)
        }
    }
}
