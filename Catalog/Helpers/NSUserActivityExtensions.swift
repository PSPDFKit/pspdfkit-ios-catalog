//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

public extension NSUserActivity {

    static private var PSCOpenExampleActivityType = "com.pspdfkit.catalog.openExample"
    static private var PSCPreferredExampleLanguageKey = "preferredExampleLanguage"
    static private var PSCIndexPathRowKey = "indexPathRow"
    static private var PSCIndexPathSectionKey = "indexPathSection"

    @objc(psc_openExampleActivityWithPreferredExampleLanguage:indexPath:)
    class func openExampleActivity(withPreferredExampleLanguage preferredExampleLanguage: ExampleLanguage, indexPath: IndexPath) -> NSUserActivity {
        let activity = self.init(activityType: PSCOpenExampleActivityType)
        activity.title = "Open Example"
        activity.userInfo = [
            PSCPreferredExampleLanguageKey: NSNumber(value: preferredExampleLanguage.rawValue),
            PSCIndexPathRowKey: NSNumber(value: indexPath.row),
            PSCIndexPathSectionKey: NSNumber(value: indexPath.section)
        ]
        return activity
    }

    @objc(psc_isOpenExampleActivity)
    var isOpenExampleActivity: Bool {
        return self.activityType == NSUserActivity.PSCOpenExampleActivityType
    }

    @objc(psc_preferredExampleLanguage)
    var preferredExampleLanguage: ExampleLanguage {
        guard self.isOpenExampleActivity,
            let rawLanguageValue = (self.userInfo?[NSUserActivity.PSCPreferredExampleLanguageKey] as? NSNumber)?.uintValue,
            let catalogExampleLanguage = ExampleLanguage(rawValue: rawLanguageValue) else {
                return .swift
        }
        return catalogExampleLanguage
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

    static private var PSCOpenDocumentActivityType = "com.pspdfkit.catalog.document"
    static private var PSCDocumentFileURLKey = "documentFileURL"

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
