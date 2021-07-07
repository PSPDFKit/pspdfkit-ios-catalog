//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class TeleprompterExample: Example {
    override init() {
        super.init()
        title = "Teleprompter example"
        category = .subclassing
        priority = 30
    }

    override func invoke(with delegate: ExampleRunnerDelegate?) -> UIViewController {
        let document = AssetLoader.document(for: .JKHF)
        let pdfViewController = AutoScrollPDFViewController(document: document)

        return pdfViewController
    }
}

class PauseAutoScrollGestureRecognizer: UIGestureRecognizer {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
            cancelsTouchesInView = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.count != 1 {
            state = .failed
            return
        }

        state = .began
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }
}

private class AutoScrollPDFViewController: PDFViewController, UIGestureRecognizerDelegate {
    var scrollTimer: Timer?
    var pauseAutoScrollGestureRecognizer: PauseAutoScrollGestureRecognizer?
    var scrollingPaused = false

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)
        updateConfiguration(builder: { builder in
            builder.pageTransition = .scrollContinuous
            builder.scrollDirection = .vertical
            })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pauseAutoScrollGestureRecognizer = PauseAutoScrollGestureRecognizer(target: self, action: #selector(handlePauseAutoScroll(_:)))
        pauseAutoScrollGestureRecognizer?.delegate = self
        if let pauseAutoScrollGestureRecognizer = pauseAutoScrollGestureRecognizer {
            documentViewController?.view.addGestureRecognizer(pauseAutoScrollGestureRecognizer)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(scroll), userInfo: nil, repeats: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scrollTimer?.invalidate()
        scrollTimer = nil
    }

    @objc func scroll() {
        if scrollingPaused {
            return
        }

        guard let documentViewController = documentViewController else { return }
        // The layout object knows how many spreads we currently have:
        let numberOfSpreads = documentViewController.layout.numberOfSpreads
        let lastSpreadIndex = CGFloat(numberOfSpreads > 0 ? numberOfSpreads - 1 : 0)

        // We scroll by updating the continuous spread index as long as we can:
        let continuousSpreadIndex: CGFloat = documentViewController.continuousSpreadIndex + 0.001
        if continuousSpreadIndex <= lastSpreadIndex {
            documentViewController.continuousSpreadIndex = continuousSpreadIndex
        }
    }

    @objc func handlePauseAutoScroll(_ tapGestureRecognizer: UITapGestureRecognizer?) {
        if tapGestureRecognizer?.state == .began {
            scrollingPaused = true
        }

        if tapGestureRecognizer?.state == .ended {
            scrollingPaused = false
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // We'll ignore long presses but allow everything else, such as scrolling.
        if gestureRecognizer == pauseAutoScrollGestureRecognizer && (otherGestureRecognizer is UILongPressGestureRecognizer) {
            return false
        }

        return true
    }
}
