//
//  Copyright © 2017-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

private protocol InsertTextViewControllerDelegate: NSObjectProtocol {
    func insertTextViewController(_ controller: InsertTextViewController, didSelectRowAt index: Int)
}

private class InsertTextViewController: BaseTableViewController {

    weak var delegate: InsertTextViewControllerDelegate?

    let cellReuseIdentifier = "InsertTextViewControllerCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.textLabel!.text = "Insert Text #\(indexPath.row)"
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.insertTextViewController(self, didSelectRowAt: indexPath.row)
    }

}

class AddTextToFreeTextAnnotationAtCaretPositionExample: Example {

    var pdfController: PDFViewController?

    override init() {
        super.init()

        title = "Add FreeText annotation and insert text at caret position"
        category = .annotations
        priority = 100
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.temporaryDocument(with: "Example Document")

        // Add the annotation
        let freeTextAnnotation = FreeTextAnnotation()
        freeTextAnnotation.color = .red
        freeTextAnnotation.contents = "This is a Free Text Annotation"
        freeTextAnnotation.fontSize = 20
        // Make the width large to ensure the text fits on one line. This will get trimmed afterwards by the call to `sizeToFit`.
        freeTextAnnotation.boundingBox = CGRect(x: 200, y: 200, width: 1000000, height: 200)

        let targetPage: PageIndex = 0
        freeTextAnnotation.pageIndex = targetPage

        freeTextAnnotation.sizeToFit()
        document.add(annotations: [freeTextAnnotation])

        let controller = PDFViewController(document: document) {
            $0.overrideClass(FreeTextAccessoryView.self, with: AddTextFreeTextAccessoryView.self)
        }
        self.pdfController = controller

        // Automate selection and entering edit mode
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            // Select annotation and get the view
            guard let pageView = controller.pageViewForPage(at: controller.pageIndex) else {
                return
            }
            pageView.selectedAnnotations = [freeTextAnnotation]
            guard let freeTextView = pageView.annotationView(for: freeTextAnnotation) as! FreeTextAnnotationView? else {
                return
            }

            // Begin editing and move caret somewhere to the front.
            freeTextView.beginEditing()
            freeTextView.textView?.selectedRange = NSRange(location: 10, length: 0)
        }

        return controller
    }
}

private class AddTextFreeTextAccessoryView: FreeTextAccessoryView, InsertTextViewControllerDelegate {

    lazy var insertTextButton: ToolbarButton = {
        let button = ToolbarButton()
        button.length = 50
        button.accessibilityLabel = "Insert Text"
        button.setTitle("Insert", for: .normal)
        button.addTarget(self, action: #selector(self.insertTextTapped), for: .touchUpInside)
        return button
    }()

    @objc func insertTextTapped(sender: FreeTextAccessoryView) {
        // Second tap should dismiss the controller.
        if dismissInsertTextViewController(animated: true) {
            return
        }

        // Present controller in a way that it's still a popover on iPhone.
        let controller = InsertTextViewController()
        controller.title = "Example Insert Text Controller"
        controller.delegate = self
        controller.modalPresentationStyle = .popover
        let options: [PresentationOption: Any] = [.popoverArrowDirections: UIPopoverArrowDirection.down.rawValue, .nonAdaptive: true, .inNavigationController: true]

        presentationContext?.actionDelegate.present(controller, options: options, animated: true, sender: sender)
    }

    @discardableResult func dismissInsertTextViewController(animated: Bool) -> Bool {
        return presentationContext!.actionDelegate.dismissViewController(of: InsertTextViewController.self, animated: animated)
    }

    // Width changes should dismiss your popover, so ensure to add your hook here.
    override func dismissPresentedViewControllers(animated: Bool) {
        super.dismissPresentedViewControllers(animated: animated)
        dismissInsertTextViewController(animated: animated)
    }

    // Adds our custom button.
    override func buttons(forWidth width: CGFloat) -> [ToolbarButton] {
        var buttons = super.buttons(forWidth: width)

        // Insert button before "Clear".
        let insertionIndex = buttons.firstIndex(of: clearButton) ?? buttons.count - 1
        buttons.insert(insertTextButton, at: insertionIndex)
        return buttons
    }

    func insertTextViewController(_ controller: InsertTextViewController, didSelectRowAt index: Int) {
        // First dismiss the `InsertTextViewController`.
        controller.dismiss(animated: true)

        // Get current page view. It not be expected for this to fail, but potentially the view hierarchy changed underneath us.
        guard let pdfController = presentationContext?.pdfController, let pageView = pdfController.pageViewForPage(at: pdfController.pageIndex) else {
            return
        }

        // Find the first free text annotation that is selected.
        // Nothing to do if no annotation is selected.
        guard let freeTextAnnotation = pageView.selectedAnnotations.first(where: { $0 is FreeTextAnnotation }) as! FreeTextAnnotation? else {
            return
        }

        // Get the view of the annotation.
        let freeTextView = pageView.annotationView(for: freeTextAnnotation) as! FreeTextAnnotationView

        // Get the text view and its selected text range (caret position).
        // Do nothing if the text view is not in the editing mode or has no caret position (both unexpected).
        guard let textView = freeTextView.textView, let selectedTextRange = textView.selectedTextRange else {
            return
        }

        // Update text at the selected range.
        let text = "--NEW TEXT AT CARET POSITION (text index #\(index))--"
        textView.replace(selectedTextRange, withText: text)
    }
}
