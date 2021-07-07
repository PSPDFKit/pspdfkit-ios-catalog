//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCExample.h"

@interface NSObject (PSPDFSwiftDetector)

/// Helps to detect if class is a Swift object. Implemented in PSPDFKit.framework (SPI)
- (BOOL)pspdf_isSwift;

@end

// Internal only
#if DEBUG
extern BOOL PSPDFAllowUnsupportedMacIdiom(Class klass);
__attribute__((constructor)) static void PSCEnableOptimizeForMacTweak(void) {
    PSPDFAllowUnsupportedMacIdiom(UIPickerView.self);
}
#endif

@implementation PSCExample

#pragma mark - Lifecycle

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

- (BOOL)isSwift {
    return self.pspdf_isSwift;
}

- (NSAttributedString *)attributedTitle {
    return [[NSAttributedString alloc] initWithString:self.title];
}

@end
