//
//  Copyright © 2011-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "Catalog-Swift.h"
#import "PSCSplitPDFViewController.h"

// It would be much better if we directly use PSPDFViewController, or reuse an embedded PSPDFViewController and modify the document via the .document property.
// This technique is used to test fast creation/destroying of the viewController.
@implementation PSCSplitPDFViewController

// MARK: - Lifecycle

- (instancetype)init {
    if ((self = [super init])) {
        self.delegate = self;
        self.navigationItem.rightBarButtonItems = @[self.thumbnailsButtonItem, self.searchButtonItem, self.activityButtonItem];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.psc_systemBackgroundColor;
}

// MARK: - Public

- (void)displayDocument:(PSPDFDocument *)document pageIndex:(PSPDFPageIndex)pageIndex {
    // anyway, set document
    self.document = document;
    self.pageIndex = pageIndex;

#if defined(PSCEnableDocumentStressTest) && PSCEnableDocumentStressTest
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [document.documentProviders.firstObject.outlineParser outline];
        //[[document copy] renderImageForPageAtIndex:0 withSize:CGSizeMake(200.0, 200.0) clippedToRect:CGRectZero withAnnotations:nil options:nil];
    });
#endif

    // Initially manually call the delegate for first load.
    [self updateTitle];
}

// MARK: - PSPDFViewControllerDelegate

- (void)updateTitle {
    if (self.document) {
        // Internally, pages start at 0. But be user-friendly and start at 1.
        self.title = [NSString stringWithFormat:@"%@ - Page %tu", self.document.title, self.pageIndex];
    } else {
        self.title = @"No document loaded.";
    }
}

- (void)pdfViewController:(PSPDFViewController *)pdfController willBeginDisplayingPageView:(PSPDFPageView *)pageView forPageAtIndex:(NSInteger)pageIndex {
    [self updateTitle];
}

@end
