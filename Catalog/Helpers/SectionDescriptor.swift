//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// Simple model class to describe static section.
struct SectionDescriptor {

    private(set) var title: String
    private(set) var footer: String

    var contentDescriptors: [Content] = []
    var headerView: UIView?
    var isCollapsed = true

    init(title: String, footer: String) {
        self.title = title
        self.footer = footer
    }

    mutating func add(content: Content) {
        contentDescriptors.append(content)
    }

    var description: String {
        "SectionDescriptor title:\(title) footer:\(footer)"
    }
}
