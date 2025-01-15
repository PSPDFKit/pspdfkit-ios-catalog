//
//  Copyright © 2018-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

#if !os(visionOS)
class CustomPencilInteractionExample: Example {
    override init() {
        super.init()

        title = "Custom Pencil Interaction Action"
        contentDescription = "Performs a custom action in response to UIPencilInteraction."
        category = .annotations
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .welcome)
        return CustomPencilInteractionViewController(document: document)
    }

    class CustomPencilInteractionViewController: PDFViewController, UIPencilInteractionDelegate {
        override func viewDidLoad() {
            super.viewDidLoad()

            // Disable Nutrient’s default Pencil interaction handling by removing the interaction.
            // Setting the `isEnabled` property will not work because Nutrient may set this property internally.
            let builtInPencilInteraction = annotationStateManager.pencilInteraction
            builtInPencilInteraction.view?.removeInteraction(builtInPencilInteraction)

            // Add the custom interaction.
            let customPencilInteraction = UIPencilInteraction()
            customPencilInteraction.delegate = self
            view.addInteraction(customPencilInteraction)
        }

        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
            let alert = UIAlertController(title: "Apple Pencil Tap!", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true, completion: nil)
        }
    }
}
#endif
