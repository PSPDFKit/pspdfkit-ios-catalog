//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

private protocol InsertTextViewControllerDelegate: NSObjectProtocol {
    func insertTextViewController(_ controller: InsertTextViewController, didSelectRowAt index: Int)
}

private class InsertTextViewController: BaseTableViewController {

weak var delegate: InsertTextViewControllerDelegate?

// MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "PSCInsertTextTableCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: CellIdentifier)
        }
        cell?.textLabel?.text = "Insert Text #\(indexPath.row)"
        return cell!
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
        freeTextAnnotation.boundingBox = CGRect(x: 200, y: 200, width: 200, height: 200)

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
            let pageView = controller.pageViewForPage(at: controller.pageIndex)
            pageView?.selectedAnnotations = [freeTextAnnotation]
            let freeTextView = pageView?.annotationView(for: freeTextAnnotation) as? FreeTextAnnotationView

            // Begin editing and move caret somewhere to the front.
            freeTextView?.beginEditing()
            freeTextView?.textView?.selectedRange = NSRange(location: 10, length: 0)
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
        return (presentationContext?.actionDelegate.dismissViewController(of: InsertTextViewController.self, animated: animated))!
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
        var insertionIndex = buttons.firstIndex(of: clearButton)
        if insertionIndex == nil {
            insertionIndex = buttons.count - 1
        }
        buttons.insert(insertTextButton, at: insertionIndex!)
        return buttons
    }

    func insertTextViewController(_ controller: InsertTextViewController, didSelectRowAt index: Int) {
        // First dismiss the controller
        controller.dismiss(animated: true)

        // Get current page view
        let pdfController = presentationContext?.pdfController
        let pageView = pdfController?.pageViewForPage(at: (pdfController?.pageIndex)!)

        // Find the first free text annotation that is selected.
        var freeTextAnnotation: FreeTextAnnotation?
        for annotation in (pageView?.selectedAnnotations)! {
            if annotation.isKind(of: FreeTextAnnotation.self) {
                freeTextAnnotation = annotation as? FreeTextAnnotation
                break
            }
        }

        // Nothing to do if no annotation is selected.
        guard let freeText = freeTextAnnotation else { return }

        // Get the view of the annotation
        let freeTextView = pageView?.annotationView(for: freeText) as! FreeTextAnnotationView

        // Get the text view and update text at the selected range.
        let textView = freeTextView.textView
        let selectedRange = textView?.selectedTextRange
        if let range = selectedRange {
            let text = "--NEW TEXT AT CARET POSITION (text index #\(index)--"
            textView?.replace(range, withText: text)
        }
    }
}
