//
//  Copyright © 2019-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

private let copyrightNotice = "Copyright 2019 ACMe Corp."

private class WatermarkingSharingViewController: PDFDocumentSharingViewController {
    enum WatermarkPosition {
        case none
        case cover
        case bottomLeft
        case bottomRight

        var textAttributes: [NSAttributedString.Key: Any] {
            switch self {
            case .none: return [:]

            case .cover:
                return [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 100), NSAttributedString.Key.foregroundColor: UIColor.red]

            case .bottomLeft:
                return [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.red]

            case .bottomRight:
                var rightAttributes = WatermarkPosition.bottomLeft.textAttributes

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .right

                rightAttributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle

                return rightAttributes
            }
        }

        func updateContext(_ context: CGContext, rect: CGRect) {
            switch self {
            case .none: break

            case .cover:
                context.translateBy(x: 0, y: rect.size.height / 2)
                context.rotate(by: -CGFloat.pi / 4)

            case .bottomLeft, .bottomRight:
                // Calculate the Y margin.
                let usedFont = textAttributes[NSAttributedString.Key.font] as? UIFont
                let fontSize = usedFont?.pointSize ?? 20

                let xMargin: CGFloat = self == .bottomLeft ? 10 : -10

                context.translateBy(x: xMargin, y: rect.size.height - fontSize * 1.5)
            }
        }
    }

    var watermarkPosition: WatermarkPosition = .cover

    override func configureProcessorConfigurationOptions(_ processorConfiguration: Processor.Configuration) {
        // Get a copy here to avoid capturing self in the block below.
        let position = watermarkPosition

        // Avoid messing with the processor configuration if we shouldn't be adding a watermark at all.
        guard position != .none else {
            return
        }

        // This configuration is going to be applied to all of the pages that the user selected
        // in the sharing UI. Please note that the pageIndex parameter here is based on the pages
        // being shared, not the source document. So if the user shares pages 5 through 10, the
        // first call to this closure will have pageIndex = 0, the second one pageIndex = 1, and so on.
        //
        // This closure is executed on background threads. Make sure to only use thread-safe drawing methods.
        processorConfiguration.drawOnAllCurrentPages { context, _, cropBox, _ in
            let drawingContext = NSStringDrawingContext()
            drawingContext.minimumScaleFactor = 0.1

            // Update the context to our desired position configuration
            position.updateContext(context, rect: cropBox)

            (copyrightNotice as NSString).draw(with: cropBox, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: position.textAttributes, context: drawingContext)
        }
    }
}

class CopyrightSharedContentExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Add Copyright to Shared Content"
        contentDescription = "Shows different ways to add copyright notices to shared contents."
        category = .sharing
        priority = 900
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .welcome)
        let pdfController = PDFViewController(document: document, delegate: self) {
            // Register our watermarking subclass to be used instead of the default class.
            $0.overrideClass(PDFDocumentSharingViewController.self, with: WatermarkingSharingViewController.self)
            let sharingConfiguration = DocumentSharingConfiguration {
                // Remove the ability to share as images.
                $0.fileFormatOptions.remove(.image)
                // Remove the Summary annotation option.
                $0.annotationOptions.remove(.summary)
            }
            $0.sharingConfigurations = [sharingConfiguration]
        }
        return pdfController
    }

    // MARK: - PDFViewControllerDelegate
    func pdfViewController(_ pdfController: PDFViewController, shouldShow controller: UIViewController, options: [String: Any]? = nil, animated: Bool) -> Bool {
        guard let watermarkingSharingController = controller as? WatermarkingSharingViewController else {
            return true
        }

        // Hook to change the position of the watermark based on some extra logic.
        watermarkingSharingController.watermarkPosition = .cover

        return true
    }

    func pdfViewController(_ sender: PDFViewController, menuForText glyphs: GlyphSequence, onPageView pageView: PDFPageView, appearance: EditMenuAppearance, suggestedMenu: UIMenu) -> UIMenu {
        // Modify the selected text to add our copyright information.
        let copyrightedText = [glyphs.text, copyrightNotice].joined(separator: "\n")
        // Create custom actions for copying and sharing.
        let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
            UIPasteboard.general.string = copyrightedText
        }
        let shareAction = UIAction(title: "Share…", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            let activityViewController = UIActivityViewController(activityItems: [copyrightedText], applicationActivities: nil)
            let sourceRect = sender.view.convert(glyphs.boundingBox, from: pageView.pdfCoordinateSpace)
            sender.present(activityViewController, options: [.sourceRect: sourceRect], animated: true, sender: nil)
        }
        // Replace the Copy and Share actions with our own.
        return suggestedMenu
            .replace(action: .PSPDFKit.copy, with: copyAction)
            .replace(action: .PSPDFKit.share, with: shareAction)
    }

}
