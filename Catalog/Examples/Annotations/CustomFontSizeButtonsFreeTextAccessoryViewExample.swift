//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomFontSizeButtonsFreeTextAccessoryViewExample: Example {
    override init() {
        super.init()

        title = "Customizing the Buttons for the Free Text inputAccessory"
        contentDescription = "Add custom font size buttons to free text accessory view"
        category = .annotations
        priority = 150
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(FreeTextAccessoryView.self, with: CustomFontSizeButtonsFreeTextAccessoryView.self)
        }
        return controller
    }
}

private class CustomFontSizeButtonsFreeTextAccessoryView: FreeTextAccessoryView {
    lazy var tenPointButton: ToolbarButton = {
        let button = ToolbarButton()
        button.length = 150
        button.setTitle("10pt", for: .normal)
        button.addTarget(self, action: #selector(self.tenPointButtonTapped), for: .touchUpInside)
        return button
    }()

    lazy var thirtyPointButton: ToolbarButton = {
        let button = ToolbarButton()
        button.length = 150
        button.setTitle("30pt", for: .normal)
        button.addTarget(self, action: #selector(self.thirtyPointButtonTapped), for: .touchUpInside)
        return button
    }()

    lazy var fiftyPointButton: ToolbarButton = {
        let button = ToolbarButton()
        button.length = 150
        button.setTitle("50pt", for: .normal)
        button.addTarget(self, action: #selector(self.fiftyPointButtonTapped), for: .touchUpInside)
        return button
    }()

    @objc func tenPointButtonTapped(sender: ToolbarButton) {
        setFontSize(to: 10)
    }

    @objc func thirtyPointButtonTapped(sender: ToolbarButton) {
        setFontSize(to: 30)
    }

    @objc func fiftyPointButtonTapped(sender: ToolbarButton) {
        setFontSize(to: 50)
    }

    private func setFontSize(to fontSize: CGFloat) {
        annotation.fontSize = fontSize
        let propertyKeyPath = "fontSize"
        let userInfo = [PSPDFAnnotationChangedNotificationKeyPathKey: [propertyKeyPath]]
        NotificationCenter.default.post(name: .PSPDFAnnotationChanged, object: annotation, userInfo: userInfo)
        self.delegate?.freeTextAccessoryView?(self, didChangeProperty: propertyKeyPath)
    }

    override func buttons(forWidth width: CGFloat) -> [ToolbarButton] {
        return [tenPointButton, thirtyPointButton, fiftyPointButton, fontNameButton, doneButton]
    }
}
