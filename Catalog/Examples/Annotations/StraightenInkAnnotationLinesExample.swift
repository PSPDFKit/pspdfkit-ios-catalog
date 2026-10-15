//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class StraightenInkAnnotationLinesExample: Example {
    override init() {
        super.init()

        title = "Straighten ink annotation lines"
        contentDescription = "Snaps hand-drawn ink annotations to straight lines"
        category = .annotations
        priority = 510
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        // Load a sample PDF document for demonstration
        let document = AssetLoader.writableDocument(for: .welcome, overrideIfExists: false)

        let controller = StraightLineHighlighterViewController(document: document) { configuration in
            // Set ink annotations to create separate annotations for each stroke.
            // This is crucial for straightening to work properly because:
            // - `.separate` mode fires PSPDFAnnotationsAdded immediately after each stroke is completed
            // - This gives us the complete line data to analyze and straighten
            // - `.mergeIfPossible` would fire PSPDFAnnotationsAdded only after the first stroke
            // - Without `.separate`, only the first stroke would be straightened
            configuration.drawCreateMode = .separate
        }

        return controller
    }

    // MARK: - Custom PDF View Controller with Straight Line Highlighting

    private class StraightLineHighlighterViewController: AdaptivePDFViewController {

        override func viewDidLoad() {
            super.viewDidLoad()

            // Observe when annotations are added to straighten them
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(annotationsAdded(_:)),
                name: .PSPDFAnnotationsAdded,
                object: nil
            )
        }

        // Note: Undoing annotation deletion will re-fire this notification,
        // causing already-straightened annotations to be reprocessed.
        @objc private func annotationsAdded(_ notification: Notification) {
            guard let annotations = notification.object as? [Annotation] else { return }
            for annotation in annotations {
                guard let inkAnnotation = annotation as? InkAnnotation,
                      inkAnnotation.document === self.document else {
                    continue
                }

                straightenInkAnnotation(inkAnnotation)
            }
        }

        private func straightenInkAnnotation(_ annotation: InkAnnotation) {
            guard let lines = annotation.lines else {
                return
            }
            // Replace each stroke with its straightened version if it resembles a line.
            annotation.lines = lines.map { line in
                // Only straighten paths that are actually lines, not circles or other shapes
                if GeometryHelpers.isNearlyStraightLine(line) {
                    return GeometryHelpers.straightenLine(line)
                } else {
                    return line
                }
            }

            // Manually post a change notification so the PDF view redraws the
            // annotation with its updated geometry.
            NotificationCenter.default.post(
                name: .PSPDFAnnotationChanged,
                object: annotation,
                userInfo: [PSPDFAnnotationChangedNotificationKeyPathKey: ["lines"]]
            )
        }

    }

}

// MARK: - Geometry Helpers

private enum GeometryHelpers {

    /// Determines if a drawn line is approximately straight.
    /// A linearity threshold of 0.7 allows for moderate hand wobble.
    static func isNearlyStraightLine(_ line: [DrawingPoint]) -> Bool {
        calculateLinearity(of: line) >= 0.7
    }

    /// Calculates how "line-like" a path is (0.0 = very curved, 1.0 = perfectly straight).
    /// Measures average perpendicular distance of intermediate points from the start-to-end line,
    /// normalized by the line length, then maps to [0, 1] via exponential decay.
    static func calculateLinearity(of line: [DrawingPoint]) -> CGFloat {
        guard line.count >= 3,
              let firstLocation = line.first?.location,
              let lastLocation = line.last?.location else { return 1.0 }

        // If start and end are nearly the same point, the stroke is a dot or closed
        // shape rather than a line, so treat it as non-straight.
        let directDistance = hypot(lastLocation.x - firstLocation.x, lastLocation.y - firstLocation.y)
        guard directDistance > 0.001 else { return 0.0 }

        // Calculate average deviation from the straight line (skip first and last points)
        let totalDeviation = line[1..<(line.count - 1)].reduce(0.0) { sum, point in
            sum + perpendicularDistance(point: point.location, lineStart: firstLocation, lineEnd: lastLocation)
        }
        // Divide by directDistance so the threshold is scale-independent:
        // a long line and a short line with the same wobble ratio are treated equally.
        let normalizedDeviation = (totalDeviation / CGFloat(line.count - 2)) / directDistance

        // Exponential decay: small deviations → high linearity
        return exp(-normalizedDeviation * 10)
    }

    /// Perpendicular (shortest) distance from a point to the line passing through `lineStart` and `lineEnd`.
    static func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let denominator = hypot(dx, dy)
        guard denominator > 0.001 else { return 0.0 }

        let numerator = abs(dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        return numerator / denominator
    }

    /// Reduces a stroke to only its start and end points, producing a straight line.
    static func straightenLine(_ line: [DrawingPoint]) -> [DrawingPoint] {
        guard let first = line.first, let last = line.last else { return line }
        return [first, last]
    }

}
