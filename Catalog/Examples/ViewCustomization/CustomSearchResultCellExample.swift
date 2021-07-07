//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomSearchResultCellExample: Example {

    override init() {
        super.init()

        title = "Custom Search Result Cell"
        contentDescription = "Shows how to customize the table view cell for PSPDFSearchViewController."
        category = .viewCustomization
        priority = 60
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(SearchViewController.self, with: CustomSearchViewController.self)
        }
        return controller
    }
}

private class CustomSearchResultTableViewCell: UITableViewCell, SearchResultViewable {
    func configure(with searchResult: SearchResult) {
        // Custiomize the cell.
        textLabel?.text = searchResult.previewText
        textLabel?.textColor = UIColor.systemGreen
        textLabel?.numberOfLines = 0
        textLabel?.adjustsFontForContentSizeCategory = true

        let document = searchResult.document
        let pageIndex = searchResult.pageIndex
        let size = CGSize(width: 32, height: 32)
        imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        imageView?.image = try! document?.imageForPage(at: pageIndex, size: size, clippedTo: CGRect.zero, annotations: nil, options: nil)
    }
}

private class CustomSearchViewController: SearchViewController {
    override class func resultCellClass() -> (SearchResultViewable.Type) {
        return CustomSearchResultTableViewCell.self
    }
}
