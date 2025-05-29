//
//  Copyright © 2020-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

extension AssetName: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = AssetName(rawValue: value)
    }
}
