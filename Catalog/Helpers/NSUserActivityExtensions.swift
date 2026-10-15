//
//  Copyright © 2019-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

public extension NSUserActivity {

    static private let PSCOpenExampleActivityType = "com.pspdfkit.catalog.openExample"
    static private let PSCIndexPathRowKey = "indexPathRow"
    static private let PSCIndexPathSectionKey = "indexPathSection"

    @objc(psc_openExampleActivityAtindexPath:)
    class func openExampleActivity(at indexPath: IndexPath) -> NSUserActivity {
        let activity = self.init(activityType: PSCOpenExampleActivityType)
        activity.title = "Open Example"
        activity.userInfo = [
            PSCIndexPathRowKey: NSNumber(value: indexPath.row),
            PSCIndexPathSectionKey: NSNumber(value: indexPath.section)
        ]
        return activity
    }

    @objc(psc_isOpenExampleActivity)
    var isOpenExampleActivity: Bool {
        return self.activityType == NSUserActivity.PSCOpenExampleActivityType
    }

    @objc(psc_indexPath)
    var indexPath: IndexPath? {
        guard self.isOpenExampleActivity,
            let row = (self.userInfo?[NSUserActivity.PSCIndexPathRowKey] as? NSNumber)?.intValue,
            let section = (self.userInfo?[NSUserActivity.PSCIndexPathSectionKey] as? NSNumber)?.intValue else {
                return nil
        }
        let indexPath = IndexPath(row: row, section: section)
        return indexPath
    }
}

public extension NSUserActivity {

    static private let PSCOpenDocumentActivityType = "com.pspdfkit.catalog.document"
    static private let PSCDocumentFileURLKey = "documentFileURL"

    @objc(psc_openDocumentActivityForFileURL:)
    class func openDocumentActivity(forFileURL fileURL: URL) -> NSUserActivity {
        let fileURLString = fileURL.absoluteString
        let activity = self.init(activityType: PSCOpenDocumentActivityType)
        activity.title = "Open Document"
        activity.userInfo = [PSCDocumentFileURLKey: fileURLString]
        return activity
    }

    @objc(psc_isOpenDocumentActivity)
    var isOpenDocumentActivity: Bool {
        return self.activityType == NSUserActivity.PSCOpenDocumentActivityType
    }

    @objc(psc_fileURL)
    var fileURL: URL? {
        guard self.isOpenDocumentActivity,
            let fileURLString = self.userInfo?[NSUserActivity.PSCDocumentFileURLKey] as? String,
            let fileURL = URL(string: fileURLString)
            else { return nil }
        return fileURL
    }
}
