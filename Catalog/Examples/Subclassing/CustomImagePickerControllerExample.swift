//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class CustomImagePickerController: ImagePickerController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        // Setting to `PSPDFImageQualityAll` to enable the quality sheet.
        allowedImageQualities = .all
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Make sure you configured Image Permissions in your app. See https://pspdfkit.com/guides/ios/getting-started/permissions/#toc_image-permissions for more details.
    override class func availableImagePickerSourceTypes() -> [NSNumber] {
        return [NSNumber(value: UIImagePickerController.SourceType.camera.rawValue)]
    }
}

class CustomImagePickerControllerExample: Example {
    override init() {
        super.init()

        title = "Custom Image Picker"
        contentDescription = "Custom Image Picker with source type UIImagePickerControllerSourceType.camera"
        category = .subclassing
        priority = 300
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(for: .JKHF, overrideIfExists: false)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(ImagePickerController.self, with: CustomImagePickerController.self)
        }
        return controller
    }
}
