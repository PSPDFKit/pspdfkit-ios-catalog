//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit
import PSPDFKitUI

private class MirrorablePDFViewController: PDFViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SDK.shared.screenController.pdfControllerToMirror = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SDK.shared.screenController.pdfControllerToMirror = nil
    }
}

class ScreenMirroringExample: Example {

    override init() {
        super.init()
        title = "Screen Mirroring Customization Example"
        contentDescription = "Shows how to add your own view controller for screen mirroring."
        category = .viewCustomization
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = MirrorablePDFViewController(document: document) {
            $0.pageTransition = .scrollPerSpread
        }

        // We do additional config in the delegate
        SDK.shared.screenController.delegate = self

        return pdfController
    }
}

extension ScreenMirroringExample: ScreenControllerDelegate {

    internal func createPDFViewController(forMirroring screenController: ScreenController) -> PDFViewController {

        let configuration = PDFConfiguration {
            $0.pageMode = .automatic
            $0.thumbnailBarMode = .none
            $0.documentLabelEnabled = .NO
            $0.isPageLabelEnabled = false

            // Only per page scrolling is supported
            $0.pageTransition = .scrollPerSpread

            $0.galleryConfiguration = GalleryConfiguration {
                $0.allowPlayingMultipleInstances = true
                $0.usesExternalPlaybackWhileExternalScreenIsActive = false
            }

			// Set custom background for easier debugging
            $0.backgroundColor = UIColor.systemOrange
        }
        let pdfController = PDFViewController(document: screenController.pdfControllerToMirror?.document, configuration: configuration)
        return pdfController
    }

    internal func screenController(_ screenController: ScreenController, didStartMirroringFor screen: UIScreen) {
        guard let pdfController = screenController.mirrorController(for: screen),
              let window = UIApplication.shared.windows.first(where: {
                $0.rootViewController == pdfController
              }) else { return }

        // We change the root view controller to something else after mirroring started.
        let hostController = UIViewController()
        hostController.view.backgroundColor = UIColor.systemOrange
        window.rootViewController = hostController

        // Re-add pdf controller and set up positioning
        hostController.addChild(pdfController)
        pdfController.view.translatesAutoresizingMaskIntoConstraints = false
        hostController.view.addSubview(pdfController.view)
        pdfController.didMove(toParent: hostController)

        NSLayoutConstraint.activate([
            // Thumbnail Container
            pdfController.view.topAnchor.constraint(equalTo: hostController.view.topAnchor, constant: 20),
            pdfController.view.bottomAnchor.constraint(equalTo: hostController.view.bottomAnchor, constant: -20),
            pdfController.view.leadingAnchor.constraint(equalTo: hostController.view.leadingAnchor, constant: 20),
            pdfController.view.trailingAnchor.constraint(equalTo: hostController.view.trailingAnchor, constant: -20),
            ])
    }
}
