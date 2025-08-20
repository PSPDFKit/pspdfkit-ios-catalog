//
//  Copyright © 2015-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PlaygroundExample.swift' for the Swift version of this example.

@import PSPDFKit;
@import PSPDFKitUI;

#import "Catalog-Swift.h"
#import "PSCExample.h"

@interface PSCObjectiveCExample : PSCExample
@end
@implementation PSCObjectiveCExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Objective-C Playground";
        self.contentDescription = @"Alternatively, start here.";
        self.category = PSCExampleCategoryTop;
        self.targetDevice = PSCExampleTargetDeviceMaskVision | PSCExampleTargetDeviceMaskPhone | PSCExampleTargetDeviceMaskPad;
        self.priority = 2;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    // Playground is convenient for testing.
    PSPDFDocument *document = [PSCAssetLoader writableDocumentWithName:PSCAssetNameWelcome overrideIfExists:NO];

    PSPDFConfiguration *configuration = [PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        // Use the configuration to set main options for the Nutrient UI.
        builder.signatureStore = [[PSPDFKeychainSignatureStore alloc] init];
    }];

    PSPDFViewController *controller = [[PSCAdaptivePDFViewController alloc] initWithDocument:document configuration:configuration];
    return controller;
}

@end
