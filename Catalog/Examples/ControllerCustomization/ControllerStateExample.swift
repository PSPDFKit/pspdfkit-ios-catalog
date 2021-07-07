//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

private enum ControllerState: String {
    case normal
    case empty
    case error
    case locked

    func nextState() -> ControllerState {
        switch self {
        case .normal: return .empty
        case .empty: return .error
        case .error: return .locked
        case .locked: return .normal
        }
    }
}

// MARK: CustomStringConvertible

extension ControllerState: CustomStringConvertible {

    var description: String {
        return "State: \(rawValue)"
    }
}

class ControllerStateExample: Example {

    // MARK: Properties

    private weak var pdfController: PDFViewController?
    private var toggleButton: UIBarButtonItem!

    private var displayState: ControllerState = .normal {
        didSet {
            guard let pdfController = pdfController else { return }
            switch displayState {
            case .normal:
                pdfController.document = AssetLoader.document(for: .quickStart)
            case .empty:
                pdfController.document = nil
            case .error:
                pdfController.document = Document(dataProviders: [DataContainerProvider(data: Data())])
            case .locked:
                pdfController.document = AssetLoader.document(for: AssetName(rawValue: "protected.pdf"))
            }
            toggleButton.title = String(describing: displayState)
        }
    }

    override init() {
        super.init()

        title = "Controller States"
        contentDescription = "Shows default, empty, error, and locked states."
        category = .controllerCustomization
        toggleButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(ControllerStateExample.toggleButtonPressed(_:)))
    }

    @objc
    private func toggleButtonPressed(_ sender: UIBarButtonItem) {
        // If pressed, toggle to the next state.
        displayState = displayState.nextState()
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let items = [toggleButton!]
        let document = AssetLoader.document(for: .quickStart)

        pdfController = {
            let pdfController = PDFViewController(document: document)
            for viewMode: ViewMode in [.document, .documentEditor, .thumbnails] {
                pdfController.navigationItem.setRightBarButtonItems(items, for: viewMode, animated: false)
            }
            pdfController.barButtonItemsAlwaysEnabled = items
            return pdfController
        }()

        // Set displayState to trigger toggleButton title change
        displayState = .normal

        return pdfController!
    }
}
