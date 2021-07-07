//
//  Copyright © 2011-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

NS_ASSUME_NONNULL_BEGIN

// Enable this to simulate improper document usage and test high-load situations.
// Only useful for development.
#define PSCEnableDocumentStressTest 1

@interface PSCSplitPDFViewController : PSPDFViewController <UISplitViewControllerDelegate, PSPDFViewControllerDelegate>

- (void)displayDocument:(nullable PSPDFDocument *)document pageIndex:(PSPDFPageIndex)pageIndex;

@end

NS_ASSUME_NONNULL_END
