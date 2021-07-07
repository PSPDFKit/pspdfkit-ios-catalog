//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class SimpleFontPickerExample: Example {

    override init() {
        super.init()
        title = "Simple Font Picker"
        contentDescription = "Shows how to limit the choices of fonts in the font picker."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let freeTextAnnotation = FreeTextAnnotation(contents: "This is a test free-text annotation.")
        freeTextAnnotation.fillColor = .white
        freeTextAnnotation.fontSize = 30
        freeTextAnnotation.boundingBox = CGRect(x: 300, y: 300, width: 150, height: 150)
        freeTextAnnotation.sizeToFit()

        let document = AssetLoader.writableDocument(for: .JKHF, overrideIfExists: true)
        document.add(annotations: [freeTextAnnotation])

        return PDFViewController(document: document) { builder in
            builder.overrideClass(FontPickerViewController.self, with: SimpleFontPickerViewController.self)
        }
    }

}

private class SimpleFontPickerViewController: FontPickerViewController {

    private static let defaultFontFamilyDescriptors: [UIFontDescriptor] = {
        ["Arial", "Calibri", "Times New Roman", "Courier New", "Helvetica", "Comic Sans MS"].map {
            UIFontDescriptor(fontAttributes: [.name: $0])
        }
    }()

    override init(fontFamilyDescriptors: [UIFontDescriptor]?) {
        super.init(fontFamilyDescriptors: fontFamilyDescriptors ?? Self.defaultFontFamilyDescriptors)
        showDownloadableFonts = false
        searchEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
