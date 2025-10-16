//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

final class StreamingImageRequestToken: NSObject, PDFPageCellImageRequestToken {
    init(expectedSize: CGSize) {
        self.expectedSize = expectedSize
    }

    var expectedSize: CGSize
}

/// This is a custom image loader that can fetch images from the web.
/// This is useful to make thumbnails appear faster while the PDF is being downloaded.
/// Once the PDF is cached, this class simply forwards to the Nutrient built-in image loader.
@MainActor final class StreamingImageLoader: NSObject, PDFPageCellImageLoading {
    var parentLoader: PDFPageCellImageLoading
    var documentFetcher: () -> Document?

    init(parentLoader: PDFPageCellImageLoading, documentFetcher: @escaping () -> Document?) {
        self.parentLoader = parentLoader
        self.documentFetcher = documentFetcher
    }

    func requestImageForPage(at pageIndex: PageIndex, availableSize size: CGSize, completionHandler: @escaping (UIImage?, Error?) -> Void) -> PDFPageCellImageRequestToken {

        // Check if we have a streaming document and that the PDF isn't yet downloaded.
        guard let document = documentFetcher() as? StreamingDocument,
              let streamingController = document.streamingController,
              !document.streamingDefinition.fileIsCached(pageIndex: pageIndex)
        else {
            // Defer to original implementation (renders + caches the PDF)
            return parentLoader.requestImageForPage(at: pageIndex, availableSize: size, completionHandler: completionHandler)
        }

        // Prepare a render request to query the cache
        let renderRequest = MutableRenderRequest(document: document)
        renderRequest.pageIndex = pageIndex
        renderRequest.imageSize = size
        renderRequest.options = document.renderOptions(forType: .page)

        // Check cache for an existing image and call completion if one is found.
        let cache = SDK.shared.cache
        if let cachedImage = try? cache.image(for: renderRequest, imageSizeMatching: [.allowLarger, .allowSmaller]) {
            completionHandler(cachedImage, nil)
        }

        // No image cached and no PDF there. We need to download the file.
        // We reuse the token from the parent but download the image directly.
        streamingController.downloadThumbnail(at: pageIndex) { result in
            switch result {
            case .failure(let error):
                print("Failed to download image: \(error)")
                completionHandler(nil, error)
            case .success(let image):
                // We store the downloaded image in the existing cache
                print("Loaded image for pageIndex \(pageIndex)")
                renderRequest.imageSize = image.size
                cache.save(image, for: renderRequest)
                completionHandler(image, nil)
            }
        }

        return StreamingImageRequestToken(expectedSize: size)
    }

    /// Helper that configures a `PDFPageCell` to add remote image loading support via  a custom image loader.
    static func configure(cell: PDFPageCell?, documentFetcher: @escaping () -> Document?) {
        guard let cell, let imageLoader = cell.imageLoader else { return }
        let remoteImageLoader = StreamingImageLoader(parentLoader: imageLoader, documentFetcher: documentFetcher)
        cell.imageLoader = remoteImageLoader
    }
}
