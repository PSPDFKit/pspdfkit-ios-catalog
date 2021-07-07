//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class ExampleManager: NSObject {

    static let `default` = ExampleManager()

    /// Returns the example based on the preferred language.
    /// If an example doesn't exist in the selected language then the example in the other language is returned.
    func examples(forPreferredLanguage preferredLanguage: ExampleLanguage) -> [Example] {
        return allExamples.filter {
            let exampleLanguage: ExampleLanguage = $0.isSwift ? .swift : .objectiveC
            return exampleLanguage == preferredLanguage || !$0.isCounterpartExampleAvailable
        }
    }

    // MARK: - Lifecycle

    /// A sorted list of all examples found by runtime introspection.
    let allExamples: [Example] = {
        // Get all subclasses and instantiate them.
        let exampleSubclasses = PSCGetAllExampleSubclasses()
        var examples: [Example] = []
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let currentDevice: PSCExampleTargetDeviceMask = isIPad ? .pad : .phone
        for exampleSubclass in exampleSubclasses {
            guard let exampleSubclass = exampleSubclass as? Example.Type else { continue }
            let example: Example = exampleSubclass.init()
            if example.targetDevice.contains(currentDevice) {
                examples.append(example)
            }
        }

        for example in examples {
            if example.isCounterpartExampleAvailable {
                continue
            }

            // We are using the title as a unique identifier for an example showing a particular thing.
            if let counterpart = examples.first(where: { ($0.title == example.title) && ($0 != example) }) {
                example.isCounterpartExampleAvailable = true
                counterpart.isCounterpartExampleAvailable = true
            } else {
                example.isCounterpartExampleAvailable = false
            }
        }

        // Sort all examples depending on category.
        examples.sort()

        return examples
    }()

}
