//
//  Copyright © 2020-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class OfficeDocumentConversionExample: Example {

    override init() {
        super.init()

        title = "Office File Conversion"
        contentDescription = "Shows how to convert an Office file to PDF using Nutrient Document Engine."
        category = .documentProcessing
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let controller = OfficeDocumentPickerTableViewController(style: .grouped)
        controller.title = self.title
        return controller
    }
}

/// Shows UI to pick an Office file for conversion.
private class OfficeDocumentPickerTableViewController: UITableViewController {

    private static let cellReuseIdentifier = "document picker table view cell"

    override func viewDidLoad() {
        super.viewDidLoad()

#if !os(visionOS)
        tableView.keyboardDismissMode = .onDrag
#endif
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: OfficeDocumentPickerTableViewController.cellReuseIdentifier)
    }

    struct OfficeDocument {
        let fileName: String
        let fileExtension: String
        let jwt: String
        let displayName: String
    }

    struct Section {
        let header: String?
        let rows: [OfficeDocument]
        let footer: String?
    }

    /// Data to show in the table view.
    private lazy var sections: [Section] = {
        /// We need a JWT corresponding to each document we want to convert. These will be used to authenticate the
        /// document conversion request by the server.
        ///
        /// JWTs for Office file conversion need two claims:
        /// 1. `exp` claim which sets the deadline for the token validity. (Unix seconds since epoch timestamp)
        /// 2. `sha256` claim containing the SHA-256 of the Office file you are planning to convert.
        ///
        /// For more details regarding JWTs, check out our guide here:
        /// https://www.nutrient.io/guides/web/pspdfkit-server/client-authentication/#special-notes-for-mobile-document-conversion
        ///
        /// In this example, we have hardcoded the JWTs corresponding to the Office files which we are trying to convert.
        /// These JWTs will be valid only for the default public/private key pair in our server example, so if you are using
        /// a different public/private key pair for Nutrient Document Engine, these JWTs will need to be re-generated. Also note that
        /// these hardcoded JWTs are valid only for converting the specific files in our example and will need to be
        /// re-generated if you wish to convert other documents.
        let documents = [
            OfficeDocument(fileName: "Mars Surface", fileExtension: "docx", jwt: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjk5OTk5OTk5OTksInNoYTI1NiI6IjU3OWVhY2IxMzZmYzE0NTg0MDZhOTNjMzQxOWY3ZTkxZTYxNWMzZDFkYTM1YTc4MTkxNzg5ZWE5YWE4YzJhOGMifQ.ENAT4TwjTk9dBNGb_dVd_Nzk2TqpRFLEQVJui_7702PPbnVYBXgQ_RYfbckS6_5iJofENxxIOGUboxqLQGLKtA", displayName: "Word document (.docx)"),
            OfficeDocument(fileName: "Art Museums", fileExtension: "xlsx", jwt: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjk5OTk5OTk5OTksInNoYTI1NiI6IjFlMzVmMjlhOGQyM2E5NjdhZGIzZjhmNjg0NWY2MGQwYjI3OWI1NmJmMTAxN2M5ODI0ZmJiM2EwMmE2NmUwNTIifQ.DmdimV2ZCbKC6B0OfzhsLGHteBKXajokgl0hMN4b0_BFAVyNBqCp556lcWnKxnYMWJfziIyODT4RDMdoQfnZaA", displayName: "Excel document (.xlsx)"),
            OfficeDocument(fileName: "Data Sampling", fileExtension: "pptx", jwt: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjk5OTk5OTk5OTksInNoYTI1NiI6ImVmYmUyNWVjNzUyMTE0NzkxMjMyMTFhZDFjY2E1YjZiN2U5MTlmMmIxNmQxYzgxNTBkMzIyYmI1Yjc3N2MyM2QifQ.BOMUjkrF1jgu5tKBqn-xhHXvGS6u4kxr_MTFI8TZwsGROy1nP0a95TDESWPf0JDhhl80U1KUUuZUw4n-xsUahA", displayName: "Powerpoint document (.pptx)")
        ]

        return [
            Section(header: "Office file conversion powered by Nutrient Document Engine", rows: [], footer: "NOTE: This example needs a local instance of Nutrient Document Engine which supports running Office file conversion. Steps to setup the local server can be found at: https://www.nutrient.io/guides/ios/features/office-conversion/. If using a non-local Nutrient Document Engine, change the server URL appropriately."),
            Section(header: "Office file examples", rows: documents, footer: "The original Office files used in this example can be found in the Samples directory.")
        ]
    }()

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: OfficeDocumentPickerTableViewController.cellReuseIdentifier, for: indexPath)

        cell.textLabel?.textColor = tableView.tintColor
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.text = row.displayName

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = sections[indexPath.section].rows[indexPath.row]
        convertAndPresentDocument(withIdentifier: identifier)
    }

    private func convertAndPresentDocument(withIdentifier identifier: OfficeDocument) {
        /// NOTE: This example needs a local instance of Nutrient Document Engine which supports running Office file conversion.
        ///
        /// Steps to setup the local server can be found at: https://www.nutrient.io/guides/ios/features/office-conversion/
        ///
        /// If using a non-local Nutrient Document Engine, change the server URL appropriately.
        guard let serverURL = URL(string: "http://localhost:5000/i/convert_to_pdf") else {
            handleError(message: "The server URL could not be resolved.", pop: false)
            return
        }

        guard let officeFileURL = Bundle.main.url(forResource: identifier.fileName, withExtension: identifier.fileExtension, subdirectory: "Samples") else {
            handleError(message: "The source file could not be loaded.", pop: false)
            return
        }

        // Create a temporary file URL for the converted file.
        let outputURL = FileHelper.temporaryPDFFileURL(prefix: "Converted")

        // Start the conversion.
        let conversionOperation = Processor.generatePDF(from: officeFileURL, serverURL: serverURL, jwt: identifier.jwt, outputFileURL: outputURL) { [weak self] _, error in
            if let error {
                self?.handleError(message: error.localizedDescription, pop: true)
            }
        }

        /// We use a `CoordinatedFileDataProvider` pointing at the outputURL to read the file once it gets converted.
        /// It is not necessary to use a `CoordinatedFileDataProvider` here, we can also just directly create a document
        /// from the `outputURL` once the conversion operation completes. Using a `CoordinatedFileDataProvider` here has
        /// the benefit that it gives us the progress reporting UI for free. You can also create your own progress reporting
        /// UI by listening to changes on the `conversionOperation.progress.fractionCompleted` property.
        let provider = CoordinatedFileDataProvider(fileURL: outputURL, progress: conversionOperation?.progress)
        let document = Document(dataProviders: [provider])
        let controller = PDFViewController(document: document)

        navigationController?.pushViewController(controller, animated: true)
    }

    private func handleError(with title: String = "Document Conversion Error", message: String, pop: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            // The Office file cell might still be selected. Deselect so we can start over.
            if let tableView = self.tableView, let selectedIndex = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndex, animated: true)
            }
            if pop {
                self.navigationController?.popViewController(animated: true)
            }
        }))
        navigationController?.present(alert, animated: true, completion: nil)
    }
}
