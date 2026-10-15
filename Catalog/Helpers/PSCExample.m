//
//  Copyright © 2012-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCExample.h"

/// Builds a human-readable title from an example class name by removing the Swift module prefix,
/// trimming an optional `Example` suffix, and splitting the remaining camel-cased words while
/// preserving uppercase abbreviations.
static NSString *PSCDisplayTitleFromClassName(Class exampleClass) {
    NSString *className = NSStringFromClass(exampleClass);

    NSRange moduleSeparatorRange = [className rangeOfString:@"." options:NSBackwardsSearch];
    if (moduleSeparatorRange.location != NSNotFound) {
        className = [className substringFromIndex:moduleSeparatorRange.location + 1];
    }

    if ([className hasSuffix:@"Example"] && className.length > @"Example".length) {
        className = [className substringToIndex:className.length - @"Example".length];
    }

    NSError *error = nil;
    NSRegularExpression *wordRegex = [NSRegularExpression regularExpressionWithPattern:@"[A-Z]+(?=[A-Z][a-z]|$)|[A-Z]?[a-z]+|[0-9]+" options:0 error:&error];
    if (error != nil) {
        return className;
    }

    NSArray<NSTextCheckingResult *> *matches = [wordRegex matchesInString:className options:0 range:NSMakeRange(0, className.length)];
    if (matches.count == 0) {
        return className;
    }

    NSMutableArray<NSString *> *words = [NSMutableArray arrayWithCapacity:matches.count];
    for (NSTextCheckingResult *match in matches) {
        [words addObject:[className substringWithRange:match.range]];
    }

    return [words componentsJoinedByString:@" "];
}

@implementation PSCExample

// MARK: - Lifecycle

- (instancetype)init {
    if ((self = [super init])) {
        _title = PSCDisplayTitleFromClassName(self.class);
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
