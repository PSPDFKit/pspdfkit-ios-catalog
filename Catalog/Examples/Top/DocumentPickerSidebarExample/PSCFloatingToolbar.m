//
//  Copyright © 2013-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCFloatingToolbar.h"

@implementation PSCFloatingToolbar

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithWhite:0.184 alpha:1.0];
        _margin = 5;
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 4.0;
        self.opaque = NO;
    }
    return self;
}

#pragma mark - Public

- (void)setButtons:(NSArray *)buttons {
    if (buttons != _buttons) {
        [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)]; // remove old buttons.
        _buttons = buttons;
        [self updateButtons];
    }
}

#pragma mark - Private

- (void)updateButtons {
    CGFloat totalWidth = 0;
    for (UIButton *button in self.buttons) {
        [self addSubview:button];
        button.frame = CGRectMake(totalWidth, 0, 44.0, 44.0);
        totalWidth += 44.0 + self.margin;
    }

    // Update frame
    CGRect frame = self.frame;
    frame.size.width = totalWidth;
    frame.size.height = 44.0;
    self.frame = frame;
}

@end
