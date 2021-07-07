//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit

/// Internal implementation of DocumentMeasurementDatasource protocol
///
/// Please ignore the entirety of this class:
/// It is a dummy implementation creating and returning a random number of measurements for each page in a document.
class MeasurementStore: NSObject, DocumentMeasurementDatasource {
    let document: Document
    required init(document: Document) {
        var perPageMeasurements = [SpreadMeasurement]()
        var collector = [[SpreadMeasurement]]()
        let pageCount = document.pageCount
        collector.reserveCapacity(Int(pageCount))
        for pageIndex in 0 ..< pageCount {
            let info = document.pageInfoForPage(at: pageIndex)!
            let canSpanMultiplePages = pageIndex + 1 < pageCount && pageIndex % 2 == 1
            for _ in 0 ... arc4random_uniform(5) {
                perPageMeasurements.append(ConcreteMeasurement.randomMeasurement(pageInfo: info, canSpanMultiplePages: canSpanMultiplePages))
            }
            collector.append(perPageMeasurements)
            perPageMeasurements.removeAll {
                $0.pageRange.length == 1
            }
        }
        measurementsByPage = collector
        self.document = document
        super.init()
    }

    func measurements(at pageIndex: Int) -> [SpreadMeasurement] {
        measurementsByPage[pageIndex]
    }
    private let measurementsByPage: [[SpreadMeasurement]]

    final class ConcreteMeasurement: SpreadMeasurement {
        let pageRange: NSRange
        let path: CGPath
        let value: Measurement<Dimension>
        init(pageRange: NSRange, path: CGPath, value: Measurement<Dimension>) {
            self.pageRange = pageRange
            self.path = path
            self.value = value
        }
    }
}

private extension MeasurementStore.ConcreteMeasurement {
    static func randomMeasurement(pageInfo: PDFPageInfo, canSpanMultiplePages: Bool) -> MeasurementStore.ConcreteMeasurement {
        let mutablePath = CGMutablePath()
        var spaceAvailable = pageInfo.size
        if canSpanMultiplePages && arc4random_uniform(10) > 6 {
            spaceAvailable.width *= 2
        }

        func randomPoint(in space: CGSize) -> CGPoint {
            let inset = UInt32(40)
            let x = arc4random_uniform(UInt32(space.width) - inset * 2) + inset
            let y = arc4random_uniform(UInt32(space.height) - inset * 2) + inset

            return .init(x: CGFloat(x), y: CGFloat(y))
        }

        let first = randomPoint(in: spaceAvailable)
        mutablePath.move(to: first)
        let second = randomPoint(in: spaceAvailable)
        mutablePath.addLine(to: second)
        let third = randomPoint(in: spaceAvailable)
        mutablePath.addLine(to: third)

        let pages = NSRange(location: Int(pageInfo.pageIndex), length: mutablePath.boundingBox.maxX > pageInfo.size.width ? 2 : 1)
        let rawValue: Measurement<Dimension>
        if arc4random_uniform(2) == 1 {
            let firstLeg = hypot(second.x - first.x, second.y - first.y)
            let secondLeg = hypot(third.x - second.x, third.y - second.y)
            rawValue = .init(value: Double(firstLeg + secondLeg), unit: UnitLength.centimeters)
        } else {
            // some trigonometry needed:
            let row1 = CGPoint(x: second.x - first.x, y: second.y - first.y)
            let row2 = CGPoint(x: third.x - first.x, y: third.y - first.y)
            rawValue = Measurement(value: abs(Double(row1.x * row2.y - row1.y * row2.x)) * 0.5, unit: UnitArea.squareCentimeters)
        }

        return .init(pageRange: pages, path: mutablePath.copy()!, value: rawValue)
    }
}
