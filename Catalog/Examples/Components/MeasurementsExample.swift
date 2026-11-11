//
//  Copyright © 2022-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class MeasurementsExample: Example {
    override init() {
        super.init()
            title = "Measurement Tools"
            contentDescription = "Showcases support for all kinds of measurement annotations."
            category = .componentsExamples
            priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let configurationBlock = AnnotationToolConfiguration.ToolItem.measurementConfigurationBlock()

        let distance = AnnotationToolConfiguration.ToolItem(type: .line, variant: .distanceMeasurement, configurationBlock: configurationBlock)
        let perimeter = AnnotationToolConfiguration.ToolItem(type: .polyLine, variant: .perimeterMeasurement, configurationBlock: configurationBlock)
        let polygonalArea = AnnotationToolConfiguration.ToolItem(type: .polygon, variant: .polygonalAreaMeasurement, configurationBlock: configurationBlock)
        let ellipticalArea = AnnotationToolConfiguration.ToolItem(type: .circle, variant: .ellipticalAreaMeasurement, configurationBlock: configurationBlock)
        let rectangularArea = AnnotationToolConfiguration.ToolItem(type: .square, variant: .rectangularAreaMeasurement, configurationBlock: configurationBlock)
        let calibration = AnnotationToolConfiguration.ToolItem(type: .line, variant: .measurementScaleCalibration, configurationBlock: configurationBlock)
        let selection = AnnotationToolConfiguration.ToolItem(type: .selectionTool)

        let pdfController = PDFViewController(document: AssetLoader.document(for: "Measurements.pdf")) {
            // Show measurement tools in the annotation creation menu shown when
            // long pressing or secondary clicking on an empty space on a page.
            $0.createAnnotationMenuGroups = [.init(items: [
                distance,
                perimeter,
                polygonalArea,
                ellipticalArea,
                rectangularArea,
            ])]
        }

        // Show only measurement tools in the annotation toolbar. We provide different configurations
        // to tailor the grouping of the tool buttons depending on how much space is available.
        pdfController.annotationToolbarController!.annotationToolbar.configurations = [
            // Two groups for iPad at 320 pt wide.
            AnnotationToolConfiguration(annotationGroups: [
                .init(items: [distance, perimeter]),
                .init(items: [polygonalArea, ellipticalArea, rectangularArea, calibration, selection]),
            ]),

            // Three groups for most other compact widths.
            AnnotationToolConfiguration(annotationGroups: [
                .init(items: [distance]),
                .init(items: [perimeter]),
                .init(items: [polygonalArea, ellipticalArea, rectangularArea, calibration, selection]),
            ]),

            // Four groups for larger iPhones in portrait.
            AnnotationToolConfiguration(annotationGroups: [
                .init(items: [distance]),
                .init(items: [perimeter]),
                .init(items: [polygonalArea]),
                .init(items: [ellipticalArea, rectangularArea, calibration, selection]),
            ]),

            // Five groups.
            AnnotationToolConfiguration(annotationGroups: [
                .init(items: [distance]),
                .init(items: [perimeter]),
                .init(items: [polygonalArea]),
                .init(items: [ellipticalArea, rectangularArea]),
                .init(items: [calibration, selection]),
            ]),

            // Six groups.
            AnnotationToolConfiguration(annotationGroups: [
                .init(items: [distance]),
                .init(items: [perimeter]),
                .init(items: [polygonalArea]),
                .init(items: [ellipticalArea]),
                .init(items: [rectangularArea]),
                .init(items: [calibration, selection]),
            ]),

            // All seven tools in separate groups for when there is plenty of space.
            AnnotationToolConfiguration(annotationGroups: [
                .init(items: [distance]),
                .init(items: [perimeter]),
                .init(items: [polygonalArea]),
                .init(items: [ellipticalArea]),
                .init(items: [rectangularArea]),
                .init(items: [calibration]),
                .init(items: [selection]),
            ]),
        ]

        return pdfController
    }
}
