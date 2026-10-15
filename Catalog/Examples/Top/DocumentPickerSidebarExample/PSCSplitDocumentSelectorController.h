//
//  Copyright © 2011-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

@import PSPDFKitUI;

@class PSCSplitPDFViewController;

NS_ASSUME_NONNULL_BEGIN

@interface PSCSplitDocumentSelectorController : PSPDFDocumentPickerController

@property (nonatomic, weak) PSCSplitPDFViewController *masterController;

@end

NS_ASSUME_NONNULL_END
