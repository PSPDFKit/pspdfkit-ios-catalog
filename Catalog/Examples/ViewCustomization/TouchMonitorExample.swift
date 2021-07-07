//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class TouchMonitorExample: Example, UIGestureRecognizerDelegate {

    private weak var pdfController: PDFViewController?
    private weak var highlightView: UILabel?

    override init() {
        super.init()
        title = "Monitor touches"
        contentDescription = "Shows how to get a callback when the user touches anywhere in the PDFViewController's view."
        category = .viewCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = PDFViewController(document: document)

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(touchReceived(_:)))
        gestureRecognizer.delaysTouchesBegan = false
        gestureRecognizer.delaysTouchesEnded = false
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        gestureRecognizer.minimumPressDuration = 0.0
        pdfController.view.addGestureRecognizer(gestureRecognizer)

        self.pdfController = pdfController
        return pdfController
    }

    // MARK: Gesture Recognizer Delegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: Actions

    @objc func touchReceived(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .began else { return }

        if highlightView == nil {
            guard let view = pdfController?.view else { return }

            let label = UILabel()
            label.text = "Touch detected."
            label.backgroundColor = UIColor.systemRed
            label.font = UIFont.systemFont(ofSize: 40.0)
            label.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])

            highlightView = label
        }

        guard let highlightView = highlightView else { fatalError("The highlight view should have been created.") }

        highlightView.alpha = 1.0
        UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
            highlightView.alpha = 0.0
        }, completion: nil)
    }
}
