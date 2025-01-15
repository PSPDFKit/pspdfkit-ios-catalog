//
//  Copyright © 2020-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

extension UIColor {

    /// Modifies the luminance of a color so it has sufficient contrast with another color. Fully supports dynamic colors.
    ///
    /// @param targetColor The color you ideally want returned if has sufficient contrast. This can be nil, in which case a standard content color will be returned. This can be a dynamic color.
    /// @param backgroundColor The color the returned color must have sufficient contrast against. This is typically a background color. This can be a dynamic color.
    /// @return A dynamic color with sufficient contrast against backgroundColor in all trait collections. The returned color will be similar to targetColor if possible.
    class func color(from targetColor: UIColor?, withSufficientContrastTo backgroundColor: UIColor) -> UIColor {
        // Optimization for a common case.
        if targetColor == nil && isColorAboutEqual(backgroundColor, to: UIColor.systemBackground) {
            return UIColor.label
        }

        func colorFromResolvedColors(resolvedTargetColor: UIColor?, resolvedBackgroundColor: UIColor) -> UIColor {
            let backgroundLuminance = resolvedBackgroundColor.brightness
            let isDarkBackground = backgroundLuminance <= 0.5

            // Invert black/white entirely rather than turning them into 30%/70% gray. E.g. when an outline explicitly sets items to black.
            guard let yuv = resolvedTargetColor?.yuvComponents,
                  yuv.yLuminance > 0.01, yuv.yLuminance < 0.99, yuv.alpha > 0 else {
                return isDarkBackground ? UIColor.white : UIColor.black
            }

            /*
             The min/max content luminance vs background luminance looks like this:

             .  min/max
             .  luminance
             .      |
             .    1 | /
             .      |/
             .  0.5 |   /
             .      |  /
             .    0  ----- background
             .      0   1  luminance
             */
            let colorSmallestAllowableLuminanceDifference = CGFloat(0.5)
            let minLuminanceOnDark = backgroundLuminance + colorSmallestAllowableLuminanceDifference
            let maxLuminanceOnLight = backgroundLuminance - colorSmallestAllowableLuminanceDifference

            // Apply a maximum/minimum luminance in case the color is too light/dark to have enough contrast with the background.
            // Note that https://www.w3.org/TR/WCAG/#visual-audio-contrast gives poor results so we don’t use it. E.g. it says the contrast is high (5) when given dark gray (0.2) and black (0).
            // Use branches instead of min/max to reuse the existing color object if possible.
            if isDarkBackground && yuv.yLuminance < minLuminanceOnDark {
                // Dark on dark. Make it lighter.
                return UIColor(luminance: minLuminanceOnDark, chrominance: yuv.uChrominance, chrominance: yuv.vChrominance, alpha: CGFloat(1))
            } else if isDarkBackground == false && yuv.yLuminance > maxLuminanceOnLight {
                // Light on light. Make it darker.
                return UIColor(luminance: maxLuminanceOnLight, chrominance: yuv.uChrominance, chrominance: yuv.vChrominance, alpha: CGFloat(1))
            } else {
                // Contrast is already sufficient.
                return resolvedTargetColor!
            }
        }

        return UIColor(dynamicProvider: { traitCollection in
            return colorFromResolvedColors(resolvedTargetColor: targetColor?.resolvedColor(with: traitCollection), resolvedBackgroundColor: backgroundColor.resolvedColor(with: traitCollection))
        })
    }

    /// Compares colors by component with a variable tolerance.
    ///
    /// You probably don’t want to use this with dynamic colors.
    class func isColorAboutEqual(_ left: UIColor?, to right: UIColor?, tolerance: CGFloat = 0.01) -> Bool {
        guard let leftColor = left?.inRGBColorSpace.cgColor,
              let rightColor = right?.inRGBColorSpace.cgColor,
              leftColor.colorSpace?.model == rightColor.colorSpace?.model,
              let leftComponents = leftColor.components,
              let rightComponents = rightColor.components else { return false }

        return zip(leftComponents, rightComponents).allSatisfy {
            abs($0 - $1) <= tolerance
        }
    }
}

private let redLuminanceFraction = Double(0.299)
private let greenLuminanceFraction = Double(0.587)
private let blueLuminanceFraction = 1 - redLuminanceFraction - greenLuminanceFraction
private let uWeighting: Double = 0.5
private let vWeighting: Double = 0.625

// Express the color space conversion as a transformation matrix so the reverse calculation is trivial.
// simd matrices are arrays of column vectors, so this appears to be the transpose.
private let d1 = simd_make_double3(redLuminanceFraction, (uWeighting * (-redLuminanceFraction)), (vWeighting * (1 - redLuminanceFraction)))
private let d2 = simd_make_double3(greenLuminanceFraction, (uWeighting * (-greenLuminanceFraction)), vWeighting * (-greenLuminanceFraction))
private let d3 = simd_make_double3(blueLuminanceFraction, uWeighting * (1 - blueLuminanceFraction), vWeighting * (-blueLuminanceFraction))
private let PSPDFRGBToYUVTransform = simd_double3x3(columns: (d1, d2, d3))

extension UIColor {
    /// Ensures the underlying color space of the `UIColor` is RGB.
    @objc(pspdf_colorInRGBColorSpace)
    var inRGBColorSpace: UIColor {
        // UIColor helpers such as getHue:saturation:brightness:alpha: can fail if
        // we use the non-extended RGB color space.
        // https://stackoverflow.com/questions/46260228/uicolor-gethuesaturationbrightnessalpha-returns-no
        let targetColorSpaceName = CGColorSpace.extendedSRGB
        guard cgColor.colorSpace?.name != targetColorSpaceName else { return self }
        let fallback = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        guard let colorSpace = CGColorSpace(name: targetColorSpaceName),
              let rgbCGColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
            return fallback
        }
        return UIColor(cgColor: rgbCGColor)
    }

    /// Calculates the total brightness of the current color.
    @objc(pspdf_brightness)
    var brightness: CGFloat {
        guard let components = inRGBColorSpace.cgColor.components else { return 0 }

        return components[0] * CGFloat(redLuminanceFraction) +
            components[1] * CGFloat(greenLuminanceFraction) +
            components[2] * CGFloat(blueLuminanceFraction)
    }

    var colorSpaceModel: CGColorSpaceModel {
        (cgColor.colorSpace?.model)!
    }

    struct RGBColorSpaceComponents {
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var alpha: CGFloat
    }

    /// An alternative to getRed:green:blue:alpha: that works the same on iOS and OS X.
    var rgbComponents: RGBColorSpaceComponents? {
        guard let cp = cgColor.components else { return nil }
        switch colorSpaceModel {
        case .rgb:
            return RGBColorSpaceComponents(red: cp[0], green: cp[1], blue: cp[2], alpha: cp[3])
        case .monochrome:
            return RGBColorSpaceComponents(red: cp[0], green: cp[0], blue: cp[0], alpha: cp[1])
        default:
            return nil
        }
    }

    /// VUV color space
    struct YUVColorSpaceComponents {
        var yLuminance: CGFloat
        var uChrominance: CGFloat
        var vChrominance: CGFloat
        var alpha: CGFloat
    }

    class func YUVFromRGB(RGB: simd_double3) -> simd_double3 {
        simd_mul(PSPDFRGBToYUVTransform, RGB)
    }

    class func RGBFromYUV(YUV: simd_double3) -> simd_double3 {
        simd_mul(PSPDFRGBToYUVTransform.inverse, YUV)
    }

    /// Returns by reference the components that make up the color in the YUV color space.
    var yuvComponents: YUVColorSpaceComponents? {
        guard let rgb = self.rgbComponents else { return nil }
        let YUV = UIColor.YUVFromRGB(RGB: simd_make_double3(Double(rgb.red), Double(rgb.green), Double(rgb.blue)))
        return YUVColorSpaceComponents(yLuminance: CGFloat(YUV[0]), uChrominance: CGFloat(YUV[1]), vChrominance: CGFloat(YUV[2]), alpha: rgb.alpha)
    }

    /// Creates and returns a color object using the specified luminance, chrominance and opacity values.
    convenience init(luminance Y: CGFloat, chrominance U: CGFloat, chrominance V: CGFloat, alpha: CGFloat) {
        let rgb = Self.RGBFromYUV(YUV: simd_make_double3(Double(Y), Double(U), Double(V)))
        self.init(red: CGFloat(rgb[0]), green: CGFloat(rgb[1]), blue: CGFloat(rgb[2]), alpha: alpha)
    }
}
