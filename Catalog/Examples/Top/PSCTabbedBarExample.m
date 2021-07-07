//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'TabbedBarExample.swift' for the Swift version of this example.

#import "CatalogSwift.h"
#import "PSCExample.h"

@interface PSCTabbedExampleViewController : PSPDFTabbedViewController <PSPDFTabbedViewControllerDelegate>
@property (nonatomic) UIBarButtonItem *clearTabsButtonItem;
@end

@interface PSCTabbedBarExample : PSCExample
@end
@implementation PSCTabbedBarExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Tabbed Bar";
        self.contentDescription = @"Opens multiple documents in a tabbed interface.";
        self.category = PSCExampleCategoryTop;
        self.priority = 3;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    return [PSCTabbedExampleViewController new];
}

@end

@implementation PSCTabbedExampleViewController

#pragma mark - Lifecycle

- (void)commonInitWithPDFController:(nullable PSPDFViewController *)pdfController {
    [super commonInitWithPDFController:pdfController];

    // In case pdfController was nil and commonInitWithPDFController created it.
    pdfController = self.pdfController;
    self.delegate = self;

    self.navigationItem.leftItemsSupplementBackButton = YES;

    // Enable automatic persistence and restore the last state.
    self.enableAutomaticStatePersistence = YES;

    self.documentPickerController = [[PSPDFDocumentPickerController alloc] initWithDirectory:@"/Bundle/Samples" includeSubdirectories:YES library:PSPDFKitGlobal.sharedInstance.library];

    _clearTabsButtonItem = [[UIBarButtonItem alloc] initWithImage:[PSPDFKitGlobal imageNamed:@"trash"] style:UIBarButtonItemStylePlain target:self action:@selector(clearTabsButtonPressed:)];

    pdfController.barButtonItemsAlwaysEnabled = @[_clearTabsButtonItem];
    pdfController.navigationItem.leftBarButtonItems = @[_clearTabsButtonItem];

    __typeof(self) __weak weakSelf = self;
    [pdfController setUpdateSettingsForBoundsChangeBlock:^(PSPDFViewController *controller) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf updateBarButtonItems];
    }];

    // Show some documents when starting from scratch.
    if (![self restoreState] || self.documents.count == 0) {
        PSPDFDocument *aboutDocument = [PSCAssetLoader documentWithName:PSCAssetNameAbout];
        PSPDFDocument *webDocument = [PSCAssetLoader documentWithName:PSCAssetNameWeb];
        self.documents = @[aboutDocument, webDocument];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateBarButtonItems];
}

#pragma mark - Private

- (void)clearTabsButtonPressed:(id)sender {
    UIAlertController *sheetController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheetController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];

    __weak typeof(self) weakSelf = self;
    [sheetController addAction:[UIAlertAction actionWithTitle:@"Close all tabs" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                         __strong typeof(weakSelf) strongSelf = weakSelf;
                         strongSelf.documents = @[];
                     }]];

    UIPopoverPresentationController *popoverPresentation = sheetController.popoverPresentationController;
    popoverPresentation.barButtonItem = sender;

    [self presentViewController:sheetController animated:YES completion:NULL];
}

- (void)updateBarButtonItems {
    PSPDFViewController *controller = self.pdfController;

    NSMutableArray *items = [NSMutableArray arrayWithObjects:controller.thumbnailsButtonItem, controller.activityButtonItem, controller.annotationButtonItem, nil];
    // Add more items if we have space available
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        [items insertObject:controller.outlineButtonItem atIndex:2];
        [items insertObject:controller.searchButtonItem atIndex:2];
    }
    [controller.navigationItem setRightBarButtonItems:items forViewMode:PSPDFViewModeDocument animated:NO];
}

- (void)updateToolbarItems {
    self.clearTabsButtonItem.enabled = self.documents.count > 0;
}

#pragma mark - PSPDFTabbedViewControllerDelegate

- (void)multiPDFController:(PSPDFMultiDocumentViewController *)multiPDFController didChangeDocuments:(NSArray *)oldDocuments {
    // NSLog(@"didChangeDocuments: %@ (old)", oldDocuments);
    [self updateToolbarItems];
}

@end
