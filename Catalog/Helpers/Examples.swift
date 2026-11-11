//
//  Copyright © 2021-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

@MainActor enum Examples {

    /// The sorted array of all examples found by runtime introspection.
    static let all: [Example] = {
        // Get all subclasses and instantiate them.
        let exampleSubclasses = PSCGetAllExampleSubclasses()
        var examples: [Example] = []

        let currentDevice: PSCExampleTargetDeviceMask
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            currentDevice = .pad
        case .vision:
            currentDevice = .vision
        default:
            currentDevice = .phone
        }

        for exampleSubclass in exampleSubclasses {
            guard let exampleSubclass = exampleSubclass as? Example.Type else { continue }
            let example: Example = exampleSubclass.init()
            if example.targetDevice.contains(currentDevice) {
                examples.append(example)
            }
        }
        return examples.sorted()
    }()

}
