//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class FormDigitalSigningExample: Example {

    // MARK: Digital signing process

    override init() {
        super.init()
        title = "Digital signing process"
        category = .forms
        priority = 15
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let p12URL = AssetLoader.assetURL(for: "JohnAppleseed.p12")
        guard let p12data = try? Data(contentsOf: p12URL) else {
            print("Error reading p12 data from \(String(describing: p12URL))")
            return PDFViewController()
        }
        let p12 = PKCS12(data: p12data)
        let signer = PKCS12Signer(displayName: "John Appleseed", pkcs12: p12)
        signer.reason = "Contract agreement"
        let signatureManager = SDK.shared.signatureManager
        signatureManager.clearRegisteredSigners()
        signatureManager.register(signer)
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certURL = AssetLoader.assetURL(for: "JohnAppleseed.p7c")
        let certData = try? Data(contentsOf: certURL)
        let certificates = try? X509.certificates(fromPKCS7Data: certData!)
        for x509 in certificates! {
            signatureManager.addTrustedCertificate(x509)
        }
        let unsignedDocument = AssetLoader.document(for: "Form_example.pdf")
        let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!
        let fileName = "\(UUID().uuidString).pdf"
        let path = NSTemporaryDirectory().appending(fileName)

        var signedDocument: Document?
        // sign the document
        signer.sign(signatureFormElement, usingPassword: "test", writeTo: path, appearance: nil, biometricProperties: nil, completion: {(_ success: Bool, _ document: Document, _ err: Error?) -> Void in
            signedDocument = document
        })
        return PDFViewController(document: signedDocument!)
    }
}

class FormDigitalSigningExampleCustomAppearanceExample: Example {

    // MARK: Digital signing process with custom appearance

    override init() {
        super.init()
        title = "Digital signing process with custom appearance"
        category = .forms
        priority = 16
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let p12URL = AssetLoader.assetURL(for: "JohnAppleseed.p12")
        guard let p12data = try? Data(contentsOf: p12URL) else {
            print("Error reading p12 data from \(String(describing: p12URL))")
            return PDFViewController()
        }
        let p12 = PKCS12(data: p12data)
        let signer = PKCS12Signer(displayName: "John Appleseed", pkcs12: p12)
        signer.reason = "Contract agreement"
        let signatureManager = SDK.shared.signatureManager
        signatureManager.clearRegisteredSigners()
        signatureManager.register(signer)
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certURL = AssetLoader.assetURL(for: "JohnAppleseed.p7c")
        let certData = try? Data(contentsOf: certURL)
        let certificates = try? X509.certificates(fromPKCS7Data: certData!)
        for x509 in certificates! {
            signatureManager.addTrustedCertificate(x509)
        }
        let unsignedDocument = AssetLoader.document(for: "Form_example.pdf")
        let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!
        let fileName = "\(UUID().uuidString).pdf"
        let path = NSTemporaryDirectory().appending(fileName)

        // Generate a custom PDF that we later use as appearance for the signature.
        let tempPDF = TemporaryPDFFileURL(prefix: "appearance")
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

        let appearanceStream = Annotation.AppearanceStream(fileURL: tempPDF)
        let signatureAppearance = PDFSignatureAppearance { builder in
            builder.appearanceMode = .signatureOnly
            builder.signatureWatermark = appearanceStream
        }

        var signedDocument: Document?
        // sign the document
        signer.sign(signatureFormElement, usingPassword: "test", writeTo: path, appearance: signatureAppearance, biometricProperties: nil, completion: {(_ success: Bool, _ document: Document, _ err: Error?) -> Void in
            signedDocument = document
        })
        return PDFViewController(document: signedDocument!)
    }
}

class FormFillingExample: Example {

    // MARK: Programmatic Form Filling

    override init() {
        super.init()
        title = "Programmatic Form Filling"
        contentDescription = "Automatically fills out all forms in code."
        category = .forms
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Form_example.pdf")
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

    // MARK: Lifecycle

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        let saveCopy = UIBarButtonItem(title: "Save Copy", style: .plain, target: self, action: #selector(FormFillingPDFViewController.saveCopy(_:)))
        navigationItem.setLeftBarButtonItems([pdfController.closeButtonItem, saveCopy], animated: false)
    }

    // MARK: Bar Button Item Actions

    @objc
    private func saveCopy(_ sender: UIBarButtonItem) {
        // Create a copy of the document
        let tempURL = TemporaryPDFFileURL(prefix: "copy_\(document?.fileURL?.lastPathComponent ?? "Form_example")")
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

class FormDigitallySignedModifiedExample: Example {

    // MARK: Interactive Form with a Digital Signature

    override init() {
        super.init()
        title = "Example of an Interactive Form with a Digital Signature"
        category = .forms
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Form_example_signed.pdf")

        // check if document is signed.
        if let signatureElement = document.annotations(at: 0, type: SignatureFormElement.self).first {
            print("Document is signed: \(signatureElement.isSigned) info: \(String(describing: signatureElement.signatureInfo))")
        }

        return PDFViewController(document: document)
    }
}

class FormWithFormattingExample: Example {

    // MARK: Form with formatted text fields

    override init() {
        super.init()
        title = "PDF Form with formatted text fields"
        category = .forms
        priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Forms_formatted.pdf")
        return PDFViewController(document: document)
    }
}

class FormWithFormattingReadonlyExample: Example {

    // MARK: Readonly Form

    override init() {
        super.init()
        title = "Readonly Form"
        category = .forms
        priority = 51
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: "Forms_formatted.pdf")
        return PDFViewController(document: document) {
            var editableAnnotationTypes = $0.editableAnnotationTypes
            editableAnnotationTypes?.remove(.widget)
            $0.editableAnnotationTypes = editableAnnotationTypes
        }
    }
}

class FormFillingAndSavingExample: Example {

    // MARK: Programmatically fill form and save

    override init() {
        super.init()
        title = "Programmatically fill form and save"
        category = .forms
        priority = 150
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form_example.pdf", overrideIfExists: true)
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

class FormCreationExample: Example {

    // MARK: Programmatically create a text form field

    override init() {
        super.init()
        title = "Programmatically create a text form field"
        category = .forms
        priority = 160
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form_example.pdf", overrideIfExists: true)
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

class FormResetExample: Example {

    // MARK: Programmatically reset some fields of a form PDF

    override init() {
        super.init()
        title = "Programmatically reset some fields of a form PDF"
        category = .forms
        priority = 160
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form_example.pdf", overrideIfExists: true)
        document.annotationSaveMode = .embedded

        let lastNameField = document.formParser?.findField(withFullFieldName: "Name_Last")
        if lastNameField != nil {
            lastNameField!.value = "Appleseed"
        }
        let firstNameField = document.formParser?.findField(withFullFieldName: "Name_First")
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

class PushButtonCreationExample: Example {

    // MARK: Programmatically create a push button form field with a custom image

    override init() {
        super.init()
        title = "Programmatically create a push button form field with a custom image"
        category = .forms
        priority = 170
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Get the example form and copy it to a writable location.
        let document = AssetLoader.writableDocument(for: "Form_example.pdf", overrideIfExists: true)
        document.annotationSaveMode = .disabled

        // Create a push button and position them in the document.
        let pushButtonFormElement = ButtonFormElement()
        pushButtonFormElement.boundingBox = CGRect(x: 20, y: 200, width: 100, height: 83)
        pushButtonFormElement.pageIndex = 0

        // Add a URL action.
        pushButtonFormElement.action = URLAction(urlString: "http://pspdfkit.com")

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
