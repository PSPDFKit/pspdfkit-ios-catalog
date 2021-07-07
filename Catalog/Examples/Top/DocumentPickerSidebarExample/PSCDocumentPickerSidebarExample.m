//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'DocumentPickerSidebarExample.swift' for the Swift version of this example.

#import "PSCExample.h"
#import "PSCSplitViewController.h"

@interface PSCDocumentPickerSidebarExample : PSCExample
@end
@implementation PSCDocumentPickerSidebarExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Document Picker Sidebar";
        self.contentDescription = @"Displays a Document Picker in the sidebar.";
        self.category = PSCExampleCategoryTop;
        self.priority = 5;
        self.wantsModalPresentation = YES;
        self.embedModalInNavigationController = NO;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    return [[PSCSplitViewController alloc] init];
}

@end
