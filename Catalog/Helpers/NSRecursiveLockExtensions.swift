//
//  Copyright © 2021-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

extension NSRecursiveLock {

    /// Acquires the lock to perform the given action and releases the lock at then end.
    public func withLock<T>( _ action: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try action()
    }

}
