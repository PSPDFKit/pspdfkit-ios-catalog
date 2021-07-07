//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

extension InkAnnotation {

    @objc(psc_sampleInkAnnotationInRect:)
    class func sampleInkAnnotation(in rect: CGRect) -> InkAnnotation {
        let ink = InkAnnotation()
        ink.lineWidth = 5

        ink.lines = [
            // first line
            [
                DrawingPoint(cgPoint: CGPoint(x: rect.minX, y: rect.minY)),
                DrawingPoint(cgPoint: CGPoint(x: rect.minX, y: rect.maxY)),
                DrawingPoint(cgPoint: CGPoint(x: rect.midX, y: rect.minY))
            ],
            // second line
            [
                DrawingPoint(cgPoint: CGPoint(x: rect.midX, y: rect.minY)),
                DrawingPoint(cgPoint: CGPoint(x: rect.midX, y: rect.maxY)),
                DrawingPoint(cgPoint: CGPoint(x: rect.maxX, y: rect.minY))
            ]
        ]
        return ink
    }
}
