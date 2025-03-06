//
//  Copyright © 2013-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

@import PSPDFKitUI;

@class PSCFloatingToolbar;

NS_ASSUME_NONNULL_BEGIN

/// Shows how to change the UI in a way like Dropbox did.
@interface PSCFloatingBarPDFViewController : PSPDFViewController

/// The floating toolbar showing the view mode and search buttons.
@property (nonatomic, nullable) PSCFloatingToolbar *floatingToolbar;

@end

NS_ASSUME_NONNULL_END
