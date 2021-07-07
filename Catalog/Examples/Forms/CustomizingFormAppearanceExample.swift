//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

/// This example shows how to customize the appearance of forms. We also add a
/// temporary label over text and signature fields which will disappear when
/// we type anything in the fields.
class CustomizingFormAppearanceExample: Example {

    override init() {
        super.init()

        title = "Customizing the Appearance of Forms"
        category = .forms
        priority = 10
    }

    var document: Document!

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        document = AssetLoader.writableDocument(for: "Form_example.pdf", overrideIfExists: true)

        /// These options clear out the default form field color so that
        /// we can customize it dynamically later in the example.
        let options = document.renderOptions(forType: .page)
        options.drawSignHereOverlay = false
        options.interactiveFormFillColor = UIColor.clear
        document.setRenderOptions(options, type: .page)

        let controller = PDFViewController(document: document) {
            $0.pageTransition = .scrollPerSpread
            $0.overrideClass(PDFPageView.self, with: CustomFormPDFPageView.self)
        }
        controller.delegate = self
        styleTextFieldFormElements()

        return controller
    }

    func styleTextFieldFormElements() {
        let annotations = document.annotationsForPage(at: 0, type: .widget)
        for annotation in annotations {
            if let formElement = annotation as? TextFieldFormElement {
                formElement.highlightColor = UIColor.clear
                formElement.fillColor = UIColor(red: 221.0 / 255.0, green: 240.0 / 255.0, blue: 236.0 / 255.0, alpha: 1)
                formElement.borderColor = UIColor.clear
                formElement.borderStyle = .none
                formElement.borderEffectIntensity = 0.0
            }
        }
    }
}

extension CustomizingFormAppearanceExample: PDFViewControllerDelegate {
    func pdfViewController(_ pdfController: PDFViewController, willBeginDisplaying pageView: PDFPageView, forPageAt pageIndex: Int) {
        if let pageView = pageView as? CustomFormPDFPageView {
            pageView.addLabels()
        }
    }
}

private class CustomFormPDFPageView: PDFPageView {

    /// Dictionary which keeps a mapping between the form element and its label.
    /// Used to identify which label to remove when selecting a form field.
    var labelList = [String: UILabel]()

    /// `prepareForReuse` automatically removes all unknown internal subviews.
    /// We need to clear out our mapping dictionary as well.
    override func prepareForReuse() {
        labelList.removeAll()
        super.prepareForReuse()
    }

    /// Add labels over all the text and signature fields.
    func addLabels() {
        if let document = self.presentationContext?.document {
            let annotations = document.annotationsForPage(at: UInt(self.pageIndex), type: .widget)
            for annotation in annotations {
                if let formElement = annotation as? FormElement {
                    addLabelOnFormElement(formElement: formElement)
                }
            }
        }
    }

    /// Add the label on a given form element. Only add a label if the form field is empty.
    func addLabelOnFormElement(formElement: FormElement) {
        if !(formElement.isKind(of: TextFieldFormElement.self) || formElement.isKind(of: SignatureFormElement.self)) { return }

        let label = labelList[formElement.uuid] == nil ? UILabel() : labelList[formElement.uuid]!
        if let textFieldFormElement = formElement as? TextFieldFormElement {
            if textFieldFormElement.contents != nil && textFieldFormElement.contents != "" { return }
            label.text = textFieldFormElement.textFormField?.name ?? "Text Field"
        }
        if let signatureFormElement = formElement as? SignatureFormElement {
            if signatureFormElement.isSigned || signatureFormElement.overlappingSignatureAnnotation != nil { return }
            label.text = "Signature Field"
        }

        label.frame = self.convert(formElement.boundingBox, from: self.pdfCoordinateSpace)
        label.textAlignment = .center
        label.textColor = UIColor(red: 84.0 / 255.0, green: 178.0 / 255.0, blue: 159.0 / 255.0, alpha: 1)
        label.backgroundColor = UIColor(red: 221.0 / 255.0, green: 240.0 / 255.0, blue: 236.0 / 255.0, alpha: 1)
        self.annotationContainerView.addSubview(label)
        labelList[formElement.uuid] = label
    }

    override func didSelect(_ annotations: [Annotation]) {
        super.didSelect(annotations)
        for annotation in annotations {
            if let label = labelList[annotation.uuid] {
                labelList[annotation.uuid] = nil
                label.removeFromSuperview()
            }
            if let textFieldFormElement = annotation as? TextFieldFormElement {
                textFieldFormElement.borderColor = UIColor(red: 84.0 / 255.0, green: 178.0 / 255.0, blue: 159.0 / 255.0, alpha: 1)
                textFieldFormElement.borderStyle = .solid
                textFieldFormElement.borderEffectIntensity = 1.0
            }
        }
    }

    override func didDeselect(_ annotations: [Annotation]) {
        super.didDeselect(annotations)
        for annotation in annotations {
            if let textFieldFormElement = annotation as? TextFieldFormElement {
                textFieldFormElement.borderColor = UIColor.clear
                textFieldFormElement.borderStyle = .none
                textFieldFormElement.borderEffectIntensity = 0.0
            }
            if let formElement = annotation as? FormElement {
                addLabelOnFormElement(formElement: formElement)
            }
            if let inkAnnotation = annotation as? InkAnnotation {
                if inkAnnotation.isSignature { addLabels() }
            }
        }
    }
}
