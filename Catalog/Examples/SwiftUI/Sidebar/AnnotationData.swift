//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import Combine

class AnnotationData: ObservableObject {
    @Published var document: Document? {
        didSet { loadData() }
    }

    /// The annotations keyed per page.
    @Published var annotationsPerPage: [Int: [Annotation]] = [:]

    var annotationChangeCancellation: AnyCancellable?

    /// Pages need to be sorted (dictionary keys are unsorted by default)
    var sortedPages: [Int] {
        annotationsPerPage.keys.sorted(by: <)
    }

    /// Count all annotations
    var count: Int {
        annotationsPerPage.values.reduce(0) { counter, annotations in
            counter + annotations.count
        }
    }

    /// Internally called when document is set
    private func loadData() {
        // Dictionary Page -> Annotations
        guard let document = document else { fatalError("Only call with document") }
        let visibleTypes = Annotation.Kind.all.subtracting(Annotation.Kind.link)
        // Annotations change as we modify them - it's important that we copy them to display.
        annotationsPerPage = document.allAnnotations(of: visibleTypes).mapKeys { $0.intValue }.mapValues { $0.clone() }
    }

    func startObserving() {
        annotationChangeCancellation = document!.annotationChangePublisher.sink { [weak self] _ in
            // fetch data on any load
            self?.loadData()
        }
    }

    func stopObserving() {
        annotationChangeCancellation = nil
    }
}

extension Annotation {
    // Return a string in the form of "user, date" whereas both elements are optional.
    var userAndLastModified: String {
        return [user, lastModified?.shortDateString].compactMap { $0 }.joined(separator: ", ")
    }
}

private extension Date {
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: self)

    }
}

/// Array extension for elements conforms the Copying protocol
private extension Array where Element: NSCopying {
    func clone() -> Array {
        map { $0.copy() as! Element }
    }
}

fileprivate extension Dictionary {
    /// Same values, corresponding to `map`ped keys.
    ///
    /// - Parameter transform: Accepts each key of the dictionary as its parameter
    ///   and returns a key for the new dictionary.
    /// - Postcondition: The collection of transformed keys must not contain duplicates.
    func mapKeys<Transformed>(
        _ transform: (Key) throws -> Transformed
    ) rethrows -> [Transformed: Value] {
        .init(
            uniqueKeysWithValues: try map { (try transform($0.key), $0.value) }
        )
    }
}
