//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

extension UIImage {

    /// Helper that loads an image from the catalog asset.
    @objc(initWithNameInCatalog:)
    public convenience init?(namedInCatalog name: String) {
        let bundle = Bundle(for: CatalogViewController.self)
        self.init(named: name, in: bundle, compatibleWith: nil)

    }

}
