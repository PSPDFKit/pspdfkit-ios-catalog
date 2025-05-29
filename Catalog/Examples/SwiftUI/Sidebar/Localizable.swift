//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI

protocol LocalizableIterable: RawRepresentable {
    var localizedName: LocalizedStringKey { get }

    // We don’t use CaseIterable to avoid retroactive conformances for types from PSPDFKitUI.
    // See https://github.com/swiftlang/swift-evolution/blob/main/proposals/0364-retroactive-conformance-warning.md

    /// A type that can represent a collection of all values of this type.
    associatedtype AllCases: Collection = [Self] where Self == Self.AllCases.Element

    /// A collection of all values of this type.
    static var allCases: Self.AllCases { get }
}

extension LocalizableIterable where RawValue == String {
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}
