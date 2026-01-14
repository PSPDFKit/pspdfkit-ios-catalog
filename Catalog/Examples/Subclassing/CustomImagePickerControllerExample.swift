//
//  Copyright © 2018-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

class CustomImagePickerController: ImagePickerController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        // Setting to `PSPDFImageQualityAll` to enable the quality sheet.
        allowedImageQualities = .all
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Make sure you configured Image Permissions in your app. See https://www.nutrient.io/guides/ios/getting-started/permissions/#image-permissions for more details.
    override class func availableImagePickerSourceTypes() -> [NSNumber] {
        return [NSNumber(value: UIImagePickerController.SourceType.photoLibrary.rawValue)]
    }
}

class CustomImagePickerControllerExample: Example {
    override init() {
        super.init()

        title = "Custom Image Picker"
        contentDescription = "Custom Image Picker with source type UIImagePickerControllerSourceType.photoLibrary"
        category = .subclassing
        priority = 300
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .annualReport, overrideIfExists: false)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(ImagePickerController.self, with: CustomImagePickerController.self)
        }
        return controller
    }
}
