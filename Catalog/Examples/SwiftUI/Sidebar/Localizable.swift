//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
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
