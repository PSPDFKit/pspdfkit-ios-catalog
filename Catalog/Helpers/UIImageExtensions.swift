//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

extension UIImage {

    /// Creates a colored image with optional rounded corners.
    convenience init(color: UIColor, size: CGSize) {
        // Once we drop iOS 12, we can use https://developer.apple.com/documentation/uikit/uiimage/3327300-withtintcolor instead.
        self.init(cgImage: UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: size)).image { context in
            color.setFill()
            context.fill(context.format.bounds)
        }.cgImage!)
    }

    /// Helper that loads an image from the catalog asset.
    @objc(initWithNameInCatalog:)
    public convenience init?(namedInCatalog name: String) {
        let bundle = Bundle(for: CatalogViewController.self)
        self.init(named: name, in: bundle, compatibleWith: nil)

    }

}
