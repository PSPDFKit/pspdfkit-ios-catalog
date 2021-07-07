//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'OpenInExample.swift' for the Swift version of this example.

#import "PSCExample.h"

@interface PSCOpenInExample : PSCExample <PSPDFDocumentPickerControllerDelegate>
@end
@implementation PSCOpenInExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Open In… Inbox";
        self.contentDescription = @"Displays all files in the Inbox directory via the PDFDocumentPickerController.";
        self.category = PSCExampleCategoryTop;
        self.priority = 6;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    // Add all documents in the Documents folder and subfolders (e.g. Inbox from Open In... feature)
    PSPDFDocumentPickerController *documentSelector = [[PSPDFDocumentPickerController alloc] initWithDirectory:nil includeSubdirectories:YES library:PSPDFKitGlobal.sharedInstance.library];
    documentSelector.delegate = self;
    documentSelector.fullTextSearchEnabled = YES;
    documentSelector.title = self.title;
    return documentSelector;
}

- (void)documentPickerController:(PSPDFDocumentPickerController *)controller didSelectDocument:(PSPDFDocument *)document pageIndex:(PSPDFPageIndex)pageIndex searchString:(NSString *)searchString {
    PSPDFViewController *pdfController = [[PSPDFViewController alloc] initWithDocument:document];
    pdfController.pageIndex = pageIndex;
    [pdfController.navigationItem setRightBarButtonItems:@[pdfController.thumbnailsButtonItem, pdfController.annotationButtonItem, pdfController.outlineButtonItem, pdfController.searchButtonItem, pdfController.activityButtonItem] forViewMode:PSPDFViewModeDocument animated:NO];
    [controller.navigationController pushViewController:pdfController animated:YES];
}

@end
