//
//  Copyright © 2013-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface PSCFloatingToolbar : UIView

/// Buttons will be placed next to each other.
@property (nonatomic, copy) NSArray *buttons;

/// Margin between the buttons. Defaults to 5.
@property (nonatomic) CGFloat margin;

@end

NS_ASSUME_NONNULL_END
