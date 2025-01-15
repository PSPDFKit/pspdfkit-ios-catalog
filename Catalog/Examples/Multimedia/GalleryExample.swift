//
//  Copyright © 2020-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class GalleryExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Image/Audio/Video Gallery"
        contentDescription = "Gallery example with video, images, and audio gallery items."
        category = .multimedia
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        document.annotationSaveMode = .disabled

        let pageSize = document.pageInfoForPage(at: 0)?.size ?? CGSize(width: 500, height: 500)

        // Add local image gallery on page 1
        let imageGalleryURL = URL(string: "pspdfkit://localhost/Bundle/sample.gallery")!
        let imageGalleryAnnotation = LinkAnnotation(url: imageGalleryURL)
        // y-axis is flipped in the PDF coordinate system.
        let pageTopCenter = CGPoint(x: pageSize.width / 2, y: pageSize.height)
        let imageGallerySize = CGSize(width: 300, height: 200)
        let imageGalleryPosition = CGPoint(x: pageTopCenter.x - imageGallerySize.width / 2, y: pageTopCenter.y - imageGallerySize.height)
        imageGalleryAnnotation.boundingBox = CGRect(origin: imageGalleryPosition, size: imageGallerySize)
        document.add(annotations: [imageGalleryAnnotation])

        // Add audio annotation on page 1
        let audioAnnotationURL = URL(string: "pspdfkit://localhost/Bundle/NightOwl.m4a")!
        let audioAnnotation = LinkAnnotation(url: audioAnnotationURL)
        let pageCenter = CGPoint(x: pageSize.width / 2, y: pageSize.height / 2)
        let audioAnnotationSize = CGSize(width: 300, height: 80)
        let audioAnnotationPosition = CGPoint(x: pageCenter.x - audioAnnotationSize.width / 2, y: pageCenter.y - audioAnnotationSize.height / 2)
        audioAnnotation.boundingBox = CGRect(origin: audioAnnotationPosition, size: audioAnnotationSize)
        document.add(annotations: [audioAnnotation])

        // Add a video gallery from local gallery data
        let videoGalleryURL = URL(string: "pspdfkit://localhost/Bundle/video.gallery")!
        let videoGalleryAnnotation = LinkAnnotation(url: videoGalleryURL)
        let pageBottomCenter = CGPoint(x: 0.5 * pageSize.width, y: 0)
        let videoGallerySize = CGSize(width: 380, height: 290)
        let videoGalleryPosition = CGPoint(x: pageBottomCenter.x - videoGallerySize.width / 2, y: pageBottomCenter.y / 2.0)
        videoGalleryAnnotation.boundingBox = CGRect(origin: videoGalleryPosition, size: videoGallerySize)
        document.add(annotations: [videoGalleryAnnotation])

        // Add local image on page 2
        let imageURL = Bundle.main.bundleURL.appendingPathComponent("exampleimage.jpg")
        let imageAnnotation = LinkAnnotation(url: imageURL)
        imageAnnotation.linkType = .image
        imageAnnotation.fillColor = .clear
        imageAnnotation.boundingBox = CGRect(x: 3, y: 450, width: 300, height: 150)
        imageAnnotation.pageIndex = 1
        document.add(annotations: [imageAnnotation])

        // Add local video on page 3
        let localVideoURL = URL(string: "pspdfkit://localhost/Bundle/big_buck_bunny.mp4")!
        let localVideoAnnotation = LinkAnnotation(url: localVideoURL)
        let localVideoAnnotationSize = CGSize(width: 450, height: 300)
        let localVideoAnnotationPosition = CGPoint(x: pageCenter.x - localVideoAnnotationSize.width / 2, y: pageCenter.y - localVideoAnnotationSize.height / 2)
        localVideoAnnotation.boundingBox = CGRect(origin: localVideoAnnotationPosition, size: localVideoAnnotationSize)
        localVideoAnnotation.pageIndex = 2
        document.add(annotations: [localVideoAnnotation])

        return PDFViewController(document: document)
    }
}
