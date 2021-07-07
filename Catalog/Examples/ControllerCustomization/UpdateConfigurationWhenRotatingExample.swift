//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class UpdateConfigurationWhenRotatingExample: Example {

    private weak var pdfController: PDFViewController?

    override init() {
        super.init()

        title = "Changing Configuration when Rotating Device"
        contentDescription = "Illustrates how to update the configuration when rotating the device"
        category = .controllerCustomization
        priority = 50
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.document(for: .annualReport)
        let pdfController = PDFViewController(document: document) {
            $0.isFirstPageAlwaysSingle = false
            $0.pageMode = .single
        }
        pdfController.setUpdateSettingsForBoundsChange { [weak self] _ in
            self?.updateConfigurationOnRotation()
        }
        self.pdfController = pdfController
        return pdfController
    }

    func updateConfigurationOnRotation() {
        let pdfController = self.pdfController
        pdfController?.updateConfiguration {
            if pdfController?.configuration.pageMode == .single {
                $0.pageMode = .double
                $0.pageTransition = .scrollPerSpread
            } else if pdfController?.configuration.pageMode == .double {
                $0.pageMode = .single
                $0.pageTransition = .scrollContinuous
            }
        }
    }
}
