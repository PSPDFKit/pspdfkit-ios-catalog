//
//  Copyright © 2012-2024 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCExample.h"

@implementation PSCExample

// MARK: - Lifecycle

- (instancetype)init {
    if ((self = [super init])) {
        _targetDevice = PSCExampleTargetDeviceMaskPhone | PSCExampleTargetDeviceMaskPad;
        _wantsModalPresentation = NO;
        _embedModalInNavigationController = YES;
        _prefersLargeTitles = YES;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    return nil;
}

- (NSAttributedString *)attributedTitle {
    return [[NSAttributedString alloc] initWithString:self.title];
}

@end
