//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

// MARK: Digital signing process

@MainActor class FormDigitalSigningExample: Example {

    override init() {
        super.init()
        title = "Digital signing process"
        category = .forms
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let p12URL = AssetLoader.assetURL(for: "John Appleseed Private Key.p12")
        guard let p12data = try? Data(contentsOf: p12URL) else {
            print("Error reading p12 data from \(String(describing: p12URL))")
            self.showAlert(title: "Error reading p12 data file", on: delegate.currentViewController!.navigationController!)
            return nil
        }
        let p12 = PKCS12(data: p12data)
        let signatureManager = SDK.shared.signatureManager
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certURL = AssetLoader.assetURL(for: "John Appleseed Public Key.p7c")
        let certData = try? Data(contentsOf: certURL)
        let certificates = try? X509.certificates(fromPKCS7Data: certData!)
        for x509 in certificates! {
            signatureManager.addTrustedCertificate(x509)
        }
        let fileName = "\(UUID().uuidString).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))

        Task {
            do {
                let unsignedDocument = AssetLoader.document(for: "Form.pdf")
                let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!

                let (certificates, privateKey) = try p12.unlockCertificateChain(withPassword: "test")
                // Use the demo timestamping server endpoint.
                let timestampServerURL = URL(string: "https://tsa.our.services.nutrient-powered.io/")!
                let configuration = SigningConfiguration(dataSigner: privateKey, certificates: certificates, timestampSource: timestampServerURL)
                try await unsignedDocument.sign(formElement: signatureFormElement, configuration: configuration, outputDataProvider: FileDataProvider(fileURL: url))
                delegate.currentViewController?.navigationController?.pushViewController(PDFViewController(document: Document(url: url)), animated: true)
            } catch {
                self.showAlert(title: "Couldn't add signature", message: "\(error)", on: delegate.currentViewController!.navigationController!)
                print(error)
            }
        }
        return nil
    }
}

// MARK: - Digital signing process with custom appearance

@MainActor class FormDigitalSigningExampleCustomAppearanceExample: Example {

    override init() {
        super.init()
        title = "Digital signing process with custom appearance"
        category = .forms
        priority = 16
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        // Load the private key.
        let p12URL = AssetLoader.assetURL(for: "John Appleseed Private Key.p12")
        guard let p12data = try? Data(contentsOf: p12URL) else {
            print("Error reading p12 data from \(String(describing: p12URL))")
            self.showAlert(title: "Error reading p12 data file", on: delegate.currentViewController!.navigationController!)
            return nil
        }
        let p12 = PKCS12(data: p12data)
        let signatureManager = SDK.shared.signatureManager
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certURL = AssetLoader.assetURL(for: "John Appleseed Public Key.p7c")
        let certData = try? Data(contentsOf: certURL)
        let certificates = try? X509.certificates(fromPKCS7Data: certData!)
        for x509 in certificates! {
            signatureManager.addTrustedCertificate(x509)
        }

        // Load the unsigned document to get accurate page info for the custom appearance stream.
        let unsignedDocument = AssetLoader.document(for: "Form.pdf")
        let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!

        // Generate a custom PDF that we later use as appearance for the signature.
        let tempPDF = FileHelper.temporaryPDFFileURL(prefix: "appearance")
        let format = UIGraphicsPDFRendererFormat()
        // To fill the signature form element, use the same size.
        let pageRect = CGRect(x: 0, y: 0, width: signatureFormElement.boundingBox.width, height: signatureFormElement.boundingBox.height)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        try? renderer.writePDF(to: tempPDF, withActions: { context in
            context.beginPage()

            // draw a gradient
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
            let colorLocations: [CGFloat] = [0.0, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors as CFArray,
                                            locations: colorLocations) else { return }
            context.cgContext.drawLinearGradient(gradient, start: CGPoint.zero,
                end: CGPoint(x: pageRect.size.width, y: pageRect.size.height),
                options: [])

            // draw text
            let text = "This is a custom PDF apperance"
            text.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)
            ])
        })
        print("Custom apperance stream is stored in \(tempPDF.path)")

        // Create a `PDFSignatureAppearance` that will be used for the signature appearance while signing.
        let appearanceStream = Annotation.AppearanceStream(fileURL: tempPDF)
        let signatureAppearance = PDFSignatureAppearance { builder in
            builder.appearanceMode = .signatureOnly
            builder.signatureWatermark = appearanceStream
        }

        // Create URL for the signed document destination.
        let fileName = "\(UUID().uuidString).pdf"
        let signedDocURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))

        Task {
            do {
                // Access the private key and certificate for signing.
                let (certificates, privateKey) = try p12.unlockCertificateChain(withPassword: "test")

                // Create the configuration to be used while signing.
                let configuration = SigningConfiguration(dataSigner: privateKey, certificates: certificates, appearance: signatureAppearance, reason: "I agree to the Contract Agreement terms.")

                // Sign the document using the signing configuration and providing the output destination for the signed document.
                try await unsignedDocument.sign(formElement: signatureFormElement, configuration: configuration, outputDataProvider: FileDataProvider(fileURL: signedDocURL))
                delegate.currentViewController?.navigationController?.pushViewController(PDFViewController(document: Document(url: signedDocURL)), animated: true)
            } catch {
                self.showAlert(title: "Couldn't add signature", message: "\(error)", on: delegate.currentViewController!.navigationController!)
                print(error)
            }
        }

        return nil
    }
}

// MARK: - Digital signing process using custom DataSigning

@MainActor class FormCustomDigitalSigningExample: Example {

    override init() {
        super.init()
        title = "Digital signing process using custom signing"
        category = .forms
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let signatureManager = SDK.shared.signatureManager
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certURL = AssetLoader.assetURL(for: "John Appleseed Public Key.p7c")
        let certData = try? Data(contentsOf: certURL)
        let publicCertificates = try? X509.certificates(fromPKCS7Data: certData!)
        for x509 in publicCertificates! {
            signatureManager.addTrustedCertificate(x509)
        }
        let fileName = "\(UUID().uuidString).pdf"
        let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))

        Task {
            do {
                let unsignedDocument = AssetLoader.document(for: "Form.pdf")
                let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!

                let customSigner = CustomDataSigner()
                let configuration = SigningConfiguration(dataSigner: customSigner, certificates: publicCertificates!)
                try await unsignedDocument.sign(formElement: signatureFormElement, configuration: configuration, outputDataProvider: FileDataProvider(fileURL: url))
                delegate.currentViewController?.navigationController?.pushViewController(PDFViewController(document: Document(url: url)), animated: true)
            } catch {
                self.showAlert(title: "Couldn't add signature", message: "\(error)", on: delegate.currentViewController!.navigationController!)
                print(error)
            }
        }
        return nil
    }

    private class CustomDataSigner: DataSigning {
        func sign(unsignedData: Data, hashAlgorithm: PDFSignatureHashAlgorithm) async throws -> (signedData: Data, dataFormat: PSPDFKit.SignedDataFormat) {
            // Carry out your custom data signing.
            // We will use a private key here for the sake of this example.
            // However you can use your custom signing implementation that doesn't rely on a private key.
            let p12URL = AssetLoader.assetURL(for: "John Appleseed Private Key.p12")
            let p12data = try Data(contentsOf: p12URL)
            let p12 = PKCS12(data: p12data)
            let (_, privateKey) = try p12.unlockCertificateChain(withPassword: "test")
            return try await privateKey.sign(unsignedData: unsignedData, hashAlgorithm: hashAlgorithm)
        }
    }
}

// MARK: - Programmatic form filling

class FormFillingExample: Example {

    override init() {
        super.init()
        title = "Programmatic Form Filling"
        contentDescription = "Automatically fills out all forms in code."
        category = .forms
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Form.pdf")
        document.annotationSaveMode = .disabled

        // Get all form objects and fill them in.
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            let formElements = document.annotations(at: 0, type: FormElement.self)
            for formElement in formElements {
                Thread.sleep(forTimeInterval: 0.8)
                // Always update the model on the main thread.
                DispatchQueue.main.async(execute: {() -> Void in
                    if let textFieldElement = formElement as? TextFieldFormElement {
                        let fieldName = textFieldElement.fieldName ?? ""
                        if textFieldElement.inputFormat == .date {
                            textFieldElement.contents = "01/01/2001"
                            // Telephone_Home needs exactly 7 digits
                        } else if fieldName == "Telephone_Home" {
                            textFieldElement.contents = "0123456"
                            // Social Security Number needs exactly 9 digits
                        } else if fieldName == "SSN" {
                            textFieldElement.contents = "012345678"
                            // The other phone numbers need exactly 10 digits
                        } else if fieldName == "Telephone_Work" || fieldName == "Emergency_Phone" {
                            textFieldElement.contents = "0123456789"
                            // All the other form fields don't have any special validation
                        } else {
                            textFieldElement.contents = "Test \(fieldName)"
                        }
                    } else if let buttonElement = formElement as? ButtonFormElement {
                        buttonElement.toggleButtonSelectionState()
                    }
                })
            }
        })
        return FormFillingPDFViewController(document: document)
    }
}

private final class FormFillingPDFViewController: PDFViewController {

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        let saveCopy = UIBarButtonItem(title: "Save Copy", style: .plain, target: self, action: #selector(FormFillingPDFViewController.saveCopy(_:)))
        navigationItem.setLeftBarButtonItems([pdfController.closeButtonItem, saveCopy], animated: false)
    }

    @objc
    private func saveCopy(_ sender: UIBarButtonItem) {
        // Create a copy of the document
        let tempURL = FileHelper.temporaryPDFFileURL(prefix: "copy_\(document?.fileURL?.lastPathComponent ?? "Form")")
        guard let documentURL = document?.fileURL else { return }
        try? FileManager.default.copyItem(at: documentURL, to: tempURL)

        // Transfer form values
        let documentCopy = Document(url: tempURL)
        let annotations = document?.annotations(at: 0, type: FormElement.self)
        let annotationsCopy = documentCopy.annotations(at: 0, type: FormElement.self)
        assert(annotations?.count == annotationsCopy.count, "This example is built to only fill forms - don't add/remove annotations.")
        for (index, formElement) in (annotationsCopy.enumerated()) {
            formElement.contents = annotations?[index].contents
        }
        try? documentCopy.save()
        guard let path = documentCopy.fileURL?.path else { return }
        let alert = UIAlertController(title: "Success", message: "Document copy saved to \(path)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Interactive Form with a digital signature

class FormDigitallySignedModifiedExample: Example {

    override init() {
        super.init()
        title = "Example of an Interactive Form with a Digital Signature"
        category = .forms
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Signed Form.pdf")

        // check if document is signed.
        if let signatureElement = document.annotations(at: 0, type: SignatureFormElement.self).first {
            print("Document is signed: \(signatureElement.isSigned) info: \(String(describing: signatureElement.signatureInfo))")
        }

        return PDFViewController(document: document)
    }
}

// MARK: - Form with formatted text fields

class FormWithFormattingExample: Example {

    override init() {
        super.init()
        title = "PDF Form with formatted text fields"
        category = .forms
        priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Formatted Form Fields.pdf")
        return PDFViewController(document: document)
    }
}

// MARK: - Read-only form

class FormWithFormattingReadonlyExample: Example {

    override init() {
        super.init()
        title = "Readonly Form"
        category = .forms
        priority = 51
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Formatted Form Fields.pdf")
        return PDFViewController(document: document) {
            var editableAnnotationTypes = $0.editableAnnotationTypes
            editableAnnotationTypes?.remove(.widget)
            $0.editableAnnotationTypes = editableAnnotationTypes
        }
    }
}

// MARK: - Programmatically fill form and save

class FormFillingAndSavingExample: Example {

    override init() {
        super.init()
        title = "Programmatically fill form and save"
        category = .forms
        priority = 150
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form.pdf", overrideIfExists: true)
        document.annotationSaveMode = .embedded

        for formElement: FormElement in (document.formParser?.forms)! {
            if formElement is ButtonFormElement {
                (formElement as? ButtonFormElement)?.select()
            } else if formElement is ChoiceFormElement {
                (formElement as? ChoiceFormElement)?.selectedIndices = NSIndexSet(index: 1) as IndexSet
            } else if formElement is TextFieldFormElement {
                formElement.contents = "Test"
            }
        }

        document.save { result in
            switch result {
            case .failure(let error):
                print("Error while saving: \(String(describing: error.localizedDescription))")

            case .success:
                print("File saved correctly to \(document.fileURL!.path)")
            }
        }

        return PDFViewController(document: document)
    }
}

// MARK: - Programmatically create a text form field

class FormCreationExample: Example {

    override init() {
        super.init()
        title = "Programmatically create a text form field"
        category = .forms
        priority = 160
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form.pdf", overrideIfExists: true)
        document.annotationSaveMode = .embedded

        // Create a new text field form element.
        let textFieldFormElement = TextFieldFormElement()
        textFieldFormElement.boundingBox = CGRect(x: 200, y: 100, width: 200, height: 20)
        textFieldFormElement.pageIndex = 0

        // Insert a form field for the form element. It will automatically be added to the document.
        let textFormField = try! TextFormField.insertedTextField(withFullyQualifiedName: "name", documentProvider: document.documentProviders.first!, formElement: textFieldFormElement)
        print("Text form field created successfully: \(textFormField)")

        return PDFViewController(document: document)
    }
}

// MARK: - Programmatically reset some fields of a form PDF

class FormResetExample: Example {

    override init() {
        super.init()
        title = "Programmatically reset some fields of a form PDF"
        category = .forms
        priority = 160
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form.pdf", overrideIfExists: true)
        document.annotationSaveMode = .embedded

        let lastNameField = document.formParser?.findField(withFullFieldName: "Last Name")
        if lastNameField != nil {
            lastNameField!.value = "Appleseed"
        }
        let firstNameField = document.formParser?.findField(withFullFieldName: "First Name")
        if firstNameField != nil {
            firstNameField!.value = "John"
        }
        if let checkBox = document.formParser?.findField(withFullFieldName: "HIGH SCHOOL DIPLOMA") as? ButtonFormField {
            checkBox.toggleButton(checkBox.annotations.first!)
        }
        // This should reset "High School Diploma" to default (unchecked), but "First name" and "Last name" keep their modified values.
        try! document.formParser?.resetForm([lastNameField!, firstNameField!], withFlags: .includeExclude)

        return PDFViewController(document: document)
    }
}

// MARK: - Programmatically create a push button form field with a custom image

class PushButtonCreationExample: Example {

    override init() {
        super.init()
        title = "Programmatically create a push button form field with a custom image"
        category = .forms
        priority = 170
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form.pdf", overrideIfExists: true)
        document.annotationSaveMode = .disabled

        // Create a push button and position them in the document.
        let pushButtonFormElement = ButtonFormElement()
        pushButtonFormElement.boundingBox = CGRect(x: 20, y: 200, width: 100, height: 83)
        pushButtonFormElement.pageIndex = 0

        // Add a URL action.
        pushButtonFormElement.action = URLAction(urlString: "https://www.nutrient.io/")

        // Create a new appearance characteristics and set its normal icon.
        let appearanceCharacteristics = AppearanceCharacteristics()
        appearanceCharacteristics.normalIcon = UIImage(named: "exampleimage.jpg")
        pushButtonFormElement.appearanceCharacteristics = appearanceCharacteristics

        // Insert a form field for the form element. It will automatically be added to the document.
        let pushButtonFormField = try! ButtonFormField.insertedButtonField(with: .pushButton, fullyQualifiedName: "PushButton", documentProvider: document.documentProviders.first!, formElements: [pushButtonFormElement], buttonValues: ["PushButton"])
        print("Button form field created successfully: \(pushButtonFormField)")

        return PDFViewController(document: document)
    }
}

fileprivate extension Example {

   func showAlert(title: String? = nil, message: String? = nil, on viewController: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        viewController.present(alertController, animated: true)
    }
}
