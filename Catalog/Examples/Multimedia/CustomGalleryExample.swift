//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

class CustomGalleryExample: Example {

    override init() {
        super.init()

        title = "Custom Gallery Example"
        contentDescription = "Add animated gif or inline video."
        category = .multimedia
        priority = 200
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .JKHF)
        document.annotationSaveMode = .disabled

        let image = UIImage(named: "mas_audio_b41570.gif")!
        // Extract the image size to use it to size the annotation bounds
        let imageSize = image.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
        let pageSize = document.pageInfoForPage(at: 0)?.size ?? CGSize(width: 500, height: 500)

        // Create an action with custom options to execute on tapping the embedded video.
        let trailerVideoURL = URL(string: "http://movietrailers.apple.com/movies/wb/islandoflemurs/islandoflemurs-tlr1_480p.mov?width=848&height=480")!
        let sheetVideoAction = URLAction(url: trailerVideoURL, options: [
            // Disable browser controls.
            .controlsKey: false,
            // Will present as sheet on iPad, is ignored on iPhone.
            .sizeKey: CGSize(width: 620, height: 400)
        ])

        // Using the `pspdfkit://` scheme enables automatic gallery content detection.
        let videoLink = LinkAnnotation(url: URL(string: "pspdfkit://localhost/Bundle/mas_audio_b41570.gif")!)
        videoLink.boundingBox = CGRect(x: 0, y: pageSize.height - imageSize.height - 64.0, width: imageSize.width, height: imageSize.height)
        videoLink.action?.subActions = [sheetVideoAction]
        document.add(annotations: [videoLink])

        // Adding a single video inline.
        let embeddedVideoURL = URL(string: "pspdfkit://movietrailers.apple.com/movies/wb/islandoflemurs/islandoflemurs-tlr1_480p.mov?width=848&height=480")!
        let embeddedVideoAnnotation = LinkAnnotation(url: embeddedVideoURL)
        let embeddedVideoAnnotationOrigin = CGPoint(x: pageSize.width - imageSize.width, y: pageSize.height - imageSize.height - 64)
        embeddedVideoAnnotation.boundingBox = CGRect(origin: embeddedVideoAnnotationOrigin, size: imageSize)

        // Disable playback controls of the video
        embeddedVideoAnnotation.controlsEnabled = false
        document.add(annotations: [embeddedVideoAnnotation])

        let pdfViewController = PDFViewController(document: document) {
            // Disable annotation editing.
            $0.editableAnnotationTypes = nil
        }
        return pdfViewController
    }
}
