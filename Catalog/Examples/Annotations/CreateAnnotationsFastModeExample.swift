//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit
import PSPDFKitUI

class CreateAnnotationsFastModeExample: Example {

    override init() {
        super.init()
        title = "Create Free Text Annotations Continuously"
        contentDescription = "Shows a way to disable the automatic state ending after annotation creation"
        category = .annotations
        priority = 202
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = PDFViewController(document: document) {
            $0.overrideClass(AnnotationToolbar.self, with: CustomAnnotationToolbar.self)
        }
        return pdfController
    }
}

private class CustomAnnotationToolbar: AnnotationToolbar {
    let continuousVariant = Annotation.Variant(rawValue: "continuous")

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
        let freeText = Item(type: .freeText)
        let freeTextContinuous = Item(type: .freeText, variant: continuousVariant, configurationBlock: {_, _, _ in
            return SDK.imageNamed("freetext")!.withRenderingMode(.alwaysOriginal)
        })

        let compactGroups = [
            Group(items: [freeText, freeTextContinuous])
        ]
        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [freeText]),
            Group(items: [freeTextContinuous]),
        ]
        let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)
        configurations = [compactConfiguration, regularConfiguration]
    }

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        // Re-enable the state only if we already were in the continuous creation mode.
        if newState == nil && oldState == .freeText && oldVariant == continuousVariant {
            manager.state = .freeText
            manager.variant = continuousVariant
        }

        super.annotationStateManager(manager, didChangeState: oldState, to: newState, variant: oldVariant, to: newVariant)
    }
}
