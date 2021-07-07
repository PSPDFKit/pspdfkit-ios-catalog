//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

extension ColorPalette {
    class func mainCustomPalette() -> ColorPalette {
        return ColorPalette(title: "Custom Colors", colorPatches: [
            ColorPatch(color: .white),
            ColorPatch(color: .gray),
            ColorPatch(color: .black),
            ColorPatch(color: .red),
            ColorPatch(color: .green),
            ColorPatch(color: .blue)
        ])
    }

    class func granularCustomPalette() -> ColorPalette {
        return ColorPalette(title: "Custom Colors", colorPatches: [
            ColorPatch(color: .white),
            ColorPatch(colors: [
                .lightGray,
                .gray,
                .darkGray
            ]),
            ColorPatch(color: UIColor.black),
            ColorPatch(colors: [
                UIColor.red,
                UIColor(hue: 0.0, saturation: 1.0, brightness: 0.8, alpha: 1.0),
                UIColor(hue: 0.0, saturation: 1.0, brightness: 0.6, alpha: 1.0),
                UIColor(hue: 0.0, saturation: 1.0, brightness: 0.4, alpha: 1.0),
                UIColor(hue: 0.0, saturation: 1.0, brightness: 0.2, alpha: 1.0)
            ]),
            ColorPatch(colors: [
                UIColor.green,
                UIColor(hue: 0.33333, saturation: 1.0, brightness: 0.7, alpha: 1.0),
                UIColor(hue: 0.33333, saturation: 1.0, brightness: 0.4, alpha: 1.0),
                UIColor(hue: 0.33333, saturation: 1.0, brightness: 0.1, alpha: 1.0)
            ]),
            ColorPatch(colors: [
                UIColor.blue,
                UIColor(hue: 0.66666, saturation: 1.0, brightness: 0.6, alpha: 1.0),
                UIColor(hue: 0.66666, saturation: 1.0, brightness: 0.2, alpha: 1.0)
            ])
        ])
    }
}

class CustomColorPickerFactory: ColorPickerFactory {
    override class func colorPalettes(in colorSet: ColorPatch.ColorSet) -> [ColorPalette] {
        switch colorSet {
        case .default:
            return [ColorPalette.mainCustomPalette(), ColorPalette.granularCustomPalette(), ColorPalette.hsv()]
        default:
            return super.colorPalettes(in: colorSet)
        }
    }
}

// MARK: - PSCExample

class CustomColorPickersExample: Example {

    override init() {
        super.init()

        title = "Color Pickers"
        contentDescription = "Customizes color pickers."
        category = .controllerCustomization
        priority = 20
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(ColorPickerFactory.self, with: CustomColorPickerFactory.self)
        }
        return controller
    }
}
