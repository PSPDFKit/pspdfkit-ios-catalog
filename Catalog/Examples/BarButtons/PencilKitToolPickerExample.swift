//
//  Copyright © 2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import PencilKit

/// This example replaces the annotation toolbar with `PKToolPicker`.
///
/// This essentially involves synchronizing state between the tool picker’s selected item and Nutrient’s annotation state manager.
///
/// Tweaks are made to some other aspects of the UI to fit better with the PencilKit tool picker.
///
/// This example only enables access to drawing tools. You could consider combining this with the + button
/// shown in `AnnotationInsertMenuExample` to add annotations of other types. That button could even be set
/// as the tool picker’s accessory item to more closely matches the user experience in Apple Markup,
/// although we think the user experience is better with a separate button in the main toolbar.
///
///     toolPicker.accessoryItem = insertAnnotationButtonItem
@available(iOS 18.0, *)
class PencilKitToolPickerExample: Example, AnnotationStateManagerDelegate, PKToolPickerObserver {

    override init() {
        super.init()

        title = "Tool picker from Apple PencilKit"
        contentDescription = "Replaces the annotation toolbar with PKToolPicker."
        category = .barButtons
        priority = 10
        if #unavailable(iOS 18.0) {
            targetDevice = []
        } else if ProcessInfo.processInfo.isMacCatalystApp {
            // Trying to show PKToolPicker on Mac does nothing.
            targetDevice = []
        }
    }

    private lazy var toolPicker: PKToolPicker = {
        let picker = PKToolPicker(toolItems: [
            PKToolPickerInkingItem(type: .pen),
            PKToolPickerInkingItem(type: .marker),
            PKToolPickerEraserItem(type: .bitmap),
        ])
        // Nutrient doesn’t follow UIPencilInteraction.prefersPencilOnlyDrawing so letting the user change this setting here would be confusing.
        picker.showsDrawingPolicyControls = false
        return picker
    }()

    private var pdfViewController: PDFViewController?

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        let controller = PDFViewController(document: document) {
            $0.signatureStore = KeychainSignatureStore()

            // Since the button to hide the tool picker is in the main toolbar, if the main toolbar disappeared
            // while the tool picker is visible, users without Apple Pencil would be unable to escape drawing
            // mode because a tap on the screen would draw instead of toggling the user interface visibility.
            // (This is solved for Nutrient’s built-in annotation toolbar by having an X button to hide the
            // annotation toolbar in the annotation toolbar itself.)
            $0.userInterfaceViewMode = .always

            // Hide the scrubber bar because the tool picker might be at the bottom of the window.
            $0.thumbnailBarMode = .none

            // The Select More menu item shows Nutrient’s built-in annotation toolbar.
            // Since the PKToolPicker doesn’t have a selection tool, the easiest solution is to disable this tool.
            var editableAnnotationTypes = $0.editableAnnotationTypes ?? []
            editableAnnotationTypes.remove(.selectionTool)
            $0.editableAnnotationTypes = editableAnnotationTypes

            // Some tools in the annotation creation menu will show Nutrient’s built-in annotation toolbar.
            // The simplest solution is to remove all tools from this menu. This will still allow Paste.
            $0.createAnnotationMenuGroups = []
        }

        let toggleToolPickerButtonItem = UIBarButtonItem()
        toggleToolPickerButtonItem.primaryAction = UIAction { [unowned self, unowned toggleToolPickerButtonItem] _ in
            UsernameHelper.ask(forDefaultAnnotationUsernameIfNeeded: self.pdfViewController!) { _ in
                self.toggleToolPicker(from: toggleToolPickerButtonItem)
            }
        }

        // Setting the primaryAction resets the title and image, so set these here instead of when creating the bar button item.
        toggleToolPickerButtonItem.title = "Draw"
        toggleToolPickerButtonItem.image = UIImage(systemName: "pencil.tip.crop.circle")

        controller.navigationItem.setRightBarButtonItems([controller.thumbnailsButtonItem, controller.activityButtonItem, controller.searchButtonItem, toggleToolPickerButtonItem], for: .document, animated: false)

        // Register for callbacks from the annotation state manager so we can keep the tool picker in sync.
        controller.annotationStateManager.add(self)

        pdfViewController = controller

        return controller
    }

    private func toggleToolPicker(from toggleToolPickerButtonItem: UIBarButtonItem) {
        let willShow = !toolPicker.isVisible

        if !willShow {
            toolPicker.removeObserver(self)
        } else {
            // Register for callbacks from the tool picker so we can keep the annotation state manager in sync.
            toolPicker.addObserver(self)
            // Move first responder status back in case it was lost after a modal presentation on top of the PDFViewController.
            if pdfViewController!.becomeFirstResponder() == false {
                NSLog("Couldn’t make PDFViewController first responder. The PKToolPicker might not appear.")
            }
        }

        toolPicker.colorUserInterfaceStyle = pdfViewController!.appearanceModeManager.appearanceMode.contains(.night) ? .dark : .light

        toolPicker.setVisible(willShow, forFirstResponder: pdfViewController!)

        if !willShow {
            // Must do this after hiding the tool picker otherwise we’ll set the annotation state manager state back to the tool picker’s tool just before it disappears.
            self.pdfViewController?.annotationStateManager.state = nil
        }

        // This may violate the usage restrictions of these SF Symbols, which state the symbols must “refer to Apple’s Markup feature”.
        // However Markup has no API or other way for an app to integrate with it.
        // It seems like a good user experience to use this symbol to refer to the PencilKit tool picker to match the iconography of Notes and Markup.
        toggleToolPickerButtonItem.image = UIImage(systemName: willShow ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
        toggleToolPickerButtonItem.isSelected = willShow
    }

    // MARK: - AnnotationStateManagerDelegate

    func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        // Don’t interfere during states that show a modal like adding a stamp.
        // Then after those states finish, put the state back to how it should be.
        if toolPicker.isVisible && newState == nil {
            updateAnnotationStateManagerFromToolPicker()
        }
    }

    // MARK: - PKToolPickerObserver

    func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
        updateAnnotationStateManagerFromToolPicker()
    }

    // MARK: -

    private func updateAnnotationStateManagerFromToolPicker() {
        guard let pdfViewController else {
            return
        }

        if let inkingItem = toolPicker.selectedToolItem as? PKToolPickerInkingItem {
            let variant: Annotation.Variant
            switch inkingItem.inkingTool.inkType {
            case .pen:
                variant = .inkPen
            case .marker:
                variant = .inkHighlighter
            default:
                fatalError("Unexpected inking item: \(inkingItem)")
            }
            pdfViewController.annotationStateManager.setState(.ink, variant: variant)
            pdfViewController.annotationStateManager.drawColor = inkingItem.inkingTool.color
            pdfViewController.annotationStateManager.lineWidth = inkingItem.inkingTool.width
        } else if let eraserItem = toolPicker.selectedToolItem as? PKToolPickerEraserItem {
            pdfViewController.annotationStateManager.state = .eraser
            // Selecting the object eraser sets the width to 0, so we use a default in that case.
            if eraserItem.eraserTool.width == 0 {
                pdfViewController.annotationStateManager.lineWidth = 20
            } else {
                pdfViewController.annotationStateManager.lineWidth = eraserItem.eraserTool.width
            }
        } else {
            fatalError("Unexpected tool: \(toolPicker.selectedToolItem)")
        }
    }

}
