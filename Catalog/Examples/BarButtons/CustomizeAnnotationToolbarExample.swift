//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class CustomizeAnnotationToolbarExample: Example {

    override init() {
        super.init()
        title = "Customized Annotation Toolbar"
        contentDescription = "Customizes the buttons in the annotation toolbar."
        category = .barButtons
        priority = 200
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(AnnotationToolbar.self, with: CustomizedAnnotationToolbar.self)
        }
        return controller
    }
}

class CustomizedAnnotationToolbar: AnnotationToolbar {
    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
        let highlight = Item(type: .highlight)
        let underline = Item(type: .underline)
        let freeText = Item(type: .freeText)
        let note = Item(type: .note)

        let square = Item(type: .square)
        let circle = Item(type: .circle)
        let line = Item(type: .line)

        let compactGroups = [
            Group(items: [highlight, underline, freeText, note]),
            Group(items: [square, circle, line])
        ]
        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [highlight, underline]),
            Group(items: [freeText]),
            Group(items: [note]),
            Group(items: [square, circle, line])
        ]
        let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)

        configurations = [compactConfiguration, regularConfiguration]
    }
}
