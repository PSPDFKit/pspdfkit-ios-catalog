//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class ToolbarPositionTopExample: Example {

    override init() {
        super.init()

        title = "Top Position for the Annotation and Document Editor Toolbars"
        contentDescription = "Shows how to force the top position for the annotation and document editor toolbars."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .quickStart, overrideIfExists: false)

        let configuration = PDFConfiguration {
            // When `.top` is a supported toolbar position, the document label must be disabled.
            $0.documentLabelEnabled = .NO
        }

        let controller = PDFViewController(document: document, configuration: configuration)

        controller.navigationItem.setRightBarButtonItems([controller.documentEditorButtonItem, controller.annotationButtonItem], animated: false)

        // Force `.top` for the annotation toolbar.
        let annotationToolbar = controller.annotationToolbarController?.annotationToolbar
        annotationToolbar?.supportedToolbarPositions = .top
        annotationToolbar?.toolbarPosition = .top

        // Force `.top` for the document editor toolbar.
        let documentEditorToolbar = controller.documentEditorController.toolbarController.documentEditorToolbar
        documentEditorToolbar.supportedToolbarPositions = .top
        documentEditorToolbar.toolbarPosition = .top

        return controller
    }
}
