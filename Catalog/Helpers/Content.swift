//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// Simple model class to describe static content.
class Content: NSObject {
    // objc is needed for the predicate search.
    @objc private(set) var title: NSAttributedString?
    private(set) var image: UIImage?
    private(set) var contentDescription: String?
    var category: Example.Category?
    public var example: Example?

    init(title: NSAttributedString?, image: UIImage? = nil, description: String? = nil, category: Example.Category? = nil) {
        super.init()

        self.title = title
        self.image = image
        contentDescription = description
        self.category = category
    }

    @objc var isSectionHeader: Bool {
        category != nil
    }

    override var description: String {
        return "\(super.description) title:\(title?.string ?? "N/A") description:\(contentDescription ?? "N/A")"
    }
}
