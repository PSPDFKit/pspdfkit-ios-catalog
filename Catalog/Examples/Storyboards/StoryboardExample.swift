//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class StoryboardExample: Example {
    override init() {
        super.init()

        title = "Create PDFViewController in a Storyboard"
        category = .storyboards
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        UIStoryboard(name: "MainStoryboard", bundle: nil).instantiateInitialViewController()
    }
}

// This class should not be private otherwise the Storyboard won’t be able to load it and will fall back to UITableViewController.
class StoryboardTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.cellLayoutMarginsFollowReadableWidth = true
    }

    // We don't have enough semantics to tell with just the Storyboard what want to do with the content of the table view cells, so we add some additional logic.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Only apply this if our destination is a PDFViewController.
        guard let pdfViewController = segue.destination as? PDFViewController, let cell = sender as? UITableViewCell else {
            return
        }

        // We put files names in the cells so we can use that with the Catalog’s AssetLoader helper.
        pdfViewController.document = AssetLoader.document(for: AssetName(rawValue: cell.textLabel!.text!))
    }
}
