//
//  Copyright © 2011-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

NS_ASSUME_NONNULL_BEGIN

@class PSCSplitPDFViewController;

@interface PSCSplitDocumentSelectorController : PSPDFDocumentPickerController

@property (nonatomic, weak) PSCSplitPDFViewController *masterController;

@end

NS_ASSUME_NONNULL_END
