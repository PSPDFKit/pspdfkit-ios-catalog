//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class AddImageSignatureProgramaticallyExample: Example {

    override init() {
        super.init()

        title = "Add image signature programatically"
        contentDescription = "Adds an image stamp annotation that is marked as being a signature."
        category = .annotations
        priority = 2005
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        // For this example, we’ll skip saving any modifications.
        document.annotationSaveMode = .disabled

        // Create the image annotation. For this example we use our logo but this would be an image of the user’s signature.
        let annotation = StampAnnotation(image: UIImage(named: "nutrient-logo"))
        annotation.boundingBox = CGRect(x: 100, y: 100, width: 70, height: 50)

        // Mark this image annotation as a signature.
        annotation.isSignature = true

        // Add the annotation. By default it will be added to the first page.
        document.add(annotations: [annotation])

        return PDFViewController(document: document)
    }
}
