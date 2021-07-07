//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

final class StickyHeaderExample: Example {
    override init() {
        super.init()
        title = "Sticky Thumbnail Header"
        contentDescription = "Shows how to set up a sticky and customized header in thumbnail mode."
        category = .subclassing
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController {
        return StickyHeaderViewController(document: AssetLoader.document(for: .JKHF))
    }
}

private class StickyHeaderViewController: PDFViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // First, enable the sticky header:
        if let layout = thumbnailController.collectionViewLayout as? ThumbnailFlowLayout {
            layout.stickyHeaderEnabled = true
        }

        // By default, the header view does not have a visible background.
        // This looks good when it scrolls along with the page thumbnails, but it looks terrible if you use the sticky header.
        // Because we only want to customize the header in this example, leaving the other samples untouched, we use `appearance(whenContainedInInstancesOf:)`.
        // In a typical app you would probably just use `appearance()`.
        let headerAppearance = CollectionReusableFilterView.appearance(whenContainedInInstancesOf: [StickyHeaderViewController.self])

        // For this app, a dark translucent background looks good.
        headerAppearance.backgroundStyle = CollectionReusableFilterView.Style.darkBlur
        // If that’s visually just “too much” for your app, you can tone it down by simply setting a background color instead:
        // headerAppearance.backgroundColor = .darkText

        // The filterElement is centered inside the header, but we could apply an offset if we wanted to:
        // headerAppearance.filterElementOffset = CGPoint(x: 0, y: 200)
        // Well that would obviously be silly!
        // If you comment the above line in, note that the filter does not extend beyound the header’s bounds.
        // In fact, there even is a minimum margin.

        // Let’s say we want that minimum margin to be 0 in X and two times the default in Y, so that the filterSegment shrinks noticably:
        var filterMargin: UIEdgeInsets = .zero
        filterMargin.top = 2 * PSPDFCollectionReusableFilterViewDefaultMargin
        filterMargin.bottom = filterMargin.top
        headerAppearance.minimumFilterMargin = filterMargin

        // And of course, we can also style the segmented control:
        let filterAppearance = UISegmentedControl.appearance(whenContainedInInstancesOf: [CollectionReusableFilterView.self, StickyHeaderViewController.self])
        if let font = UIFont(name: "Avenir", size: 12) {
            filterAppearance.setTitleTextAttributes([.font: font], for: .normal)
        }
        if let font = UIFont(name: "Avenir-Black", size: 12) {
            filterAppearance.setTitleTextAttributes([.font: font], for: .selected)
        }

        // That’s it!
        // If you need further customizations for the header — like inserting additional views — you do have to subclass `ThumbnailViewController`.
        // Methods to override there are (in descending order of probabbility):
        // 1. `collectionView(_:layout:referenceSizeForHeaderInSection:)` if you want to adjust the header height
        // 2. `collectionView(_:viewForSupplementaryElementOfKind:at:)` if you want to insert additional views or constraints into the header
    }
}
