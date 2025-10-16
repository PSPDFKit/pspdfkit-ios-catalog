//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class ComparisonExample: IndustryExample {

    override init() {
        super.init()
        title = "Document Comparison"
        contentDescription = "Shows how Nutrient can be used to compare PDF documents and highlight changes."
        extendedDescription = "Quickly compare, highlight, and identify PDF changes. Use manual document alignment to get a precise comparison."
        url = URL(string: "https://www.nutrient.io/guides/ios/compare-documents/")!
        category = .componentsExamples
        priority = 3
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        ComparisonViewController(example: self)
    }

}

private class ComparisonViewController: PDFTabbedViewController, DocumentAlignmentViewControllerDelegate, PDFTabbedViewControllerDelegate {

    /// Initialize the receiver with the reference to the parent example.
    init(example: IndustryExample) {
        super.init(pdfViewController: nil)
        moreInfo = MoreInfoCoordinator(with: example, presentationContext: self)
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func commonInit(withPDFController somePdfController: PDFViewController?) {
        super.commonInit(withPDFController: somePdfController)
        // Closing tabs is unsupported in this example.
        closeMode = .disabled
        // Disabling the ability to hide user interface also makes the whole
        // documents fit under the navigation bar.
        pdfController.updateConfiguration {
            $0.userInterfaceViewMode = .always
            $0.shouldShowRedactionInfoButton = false
        }
        // The old and new documents should always be visible.
        insertDocument(oldDocument, at: 0, makeVisible: false, animated: false)
        insertDocument(newDocument, at: 1, makeVisible: false, animated: false)
        // Generate the initial (misaligned) comparison document.
        let processor = ComparisonProcessor(configuration: .default())
        comparisonDocument = try! processor.comparisonDocument(oldDocument: oldDocument, newDocument: newDocument)
        // We want to update the "Align..." button visibility when selected tab
        // changes. For that we need to implement a delegate method.
        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftItemsSupplementBackButton = true
        pdfController.navigationItem.title = "Comparison"
        pdfController.navigationItem.leftBarButtonItems = [moreInfo.barButton]
        pdfController.navigationItem.rightBarButtonItems = []
        // Manually add the "Align..." button to the user interface view.
        // `PDFTabbedViewController` uses a single `PDFViewController` for all
        // tabs, so you only need to add it once and then manage its visibility.
        alignButton.translatesAutoresizingMaskIntoConstraints = false
        pdfController.userInterfaceView.addSubview(alignButton)
        NSLayoutConstraint.activate([
            alignButton.trailingAnchor.constraint(equalTo: pdfController.userInterfaceView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            alignButton.bottomAnchor.constraint(equalTo: pdfController.userInterfaceView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])
        // We want to update the "Align..." button visibility immediately.
        updateAlignButtonVisibility()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moreInfo.showAlertIfNeeded()
    }

    // MARK: Documents

    /// The old version of the document.
    private lazy var oldDocument: Document = AssetLoader.document(for: "Floor Plan A.pdf")

    /// The new version of the document.
    private lazy var newDocument: Document = AssetLoader.document(for: "Floor Plan B.pdf")

    /// The comparison document.
    private var comparisonDocument: Document? {
        didSet {
            if let oldValue {
                removeDocument(oldValue, animated: false)
            }
            if let newValue = comparisonDocument {
                insertDocument(newValue, at: 2, makeVisible: true, animated: false)
            }
        }
    }

    // MARK: User Interface

    private var moreInfo: MoreInfoCoordinator!

    private func presentDocumentAlignmentViewController() {
        // Pass the two documents to be aligned.
        let viewController = DocumentAlignmentViewController(oldDocument: oldDocument, newDocument: newDocument, configuration: .default())
        // In addition to using the delegate methods, you can also use the
        // `comparisonDocument` future to set up Combine bindings.
        viewController.delegate = self
        // Add an "x" button to the document alignment view controller so that
        // it can be used to cancel the alignment.
        viewController.navigationItem.leftBarButtonItems = [closeButtonItem]
        // Wrap the document alignment view controller in a navigation
        // controller so that it has a navigation bar.
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isModalInPresentation = true
        // UIKit will use `.pageSheet` modal presentation mode by default. You
        // can give the document alignment view controller more space by setting
        // `modalPresentationStyle` for `navigationController` to `.fullScreen`.
        present(navigationController, animated: true)
    }

    private lazy var alignButton: UIButton = {
        let button = DocumentAlignmentButton()
        button.addTarget(self, action: #selector(alignButtonPressed), for: .touchUpInside)
        return button
    }()

    @objc private func alignButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Manual Alignment",
            message: """
            Select 3 points on both documents for manual alignment. For best \
            results, choose points near corners of the document, and make sure \
            to choose the points in the same order on both documents.
            """,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Continue",
            style: .cancel,
            handler: { [self] _ in
                presentDocumentAlignmentViewController()
            }
        ))
        present(alert, animated: true)
    }

    private func updateAlignButtonVisibility() {
        // Show the "Align..." button only in the tab containing the comparison
        // document.
        alignButton.isHidden = visibleDocument !== comparisonDocument
    }

    private lazy var closeButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonItemPressed))

    @objc private func closeButtonItemPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    // MARK: DocumentAlignmentViewControllerDelegate

    func documentAlignmentViewController(_ sender: DocumentAlignmentViewController, didFinishWithComparisonDocument document: Document) {
        comparisonDocument = document
        dismiss(animated: true)
    }

    func documentAlignmentViewController(_ sender: DocumentAlignmentViewController, didFailWithError error: Error) {
        dismiss(animated: true) { [self] in
            let alert = UIAlertController(title: "Couldn’t Create the Comparison Document", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: PDFTabbedViewControllerDelegate

    func tabbedPDFController(_ tabbedPDFController: PDFTabbedViewController, didChangeVisibleDocument oldVisibleDocument: Document?) {
        updateAlignButtonVisibility()
    }

}
