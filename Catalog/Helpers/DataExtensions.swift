//
//  Copyright © 2025-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

extension Data {

    /// Converts data to hexadecimal format
    /// - Returns: Hexadecimal string or nil if conversion fails
    func hexadecimalEncodedString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
