//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DocumentViewStateRestoration: Example, PDFViewControllerDelegate {

    let viewStateKey = "viewStateKey"

    override init() {
        super.init()

        title = "Document View State Restoration"
        contentDescription = "Restores document to a previously stored reading position."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
           let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

           let controller = PDFViewController(document: document)
           controller.delegate = self

           // Apply the saved view state.
           if let data = UserDefaults.standard.object(forKey: viewStateKey) as? Data,
            let unarchivedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [PDFViewState.self], from: data),
            let state = unarchivedObject as? PDFViewState {
               controller.applyViewState(state, animateIfPossible: true)
           }

           return controller
    }

    // MARK: - PDFViewControllerDelegate
    func pdfViewControllerWillDismiss(_ pdfController: PDFViewController) {
        // Persist the current view state.
        guard let viewState = pdfController.viewState,
            let data = try? NSKeyedArchiver.archivedData(withRootObject: viewState, requiringSecureCoding: true) else {
            print("Error archiving view state.")
            return
        }

        UserDefaults.standard.set(data, forKey: viewStateKey)
    }
}
