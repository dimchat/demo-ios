//
//  UIView+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/7.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Gesture)

- (void)addTapTarget:(nullable id)target action:(nullable SEL)selector count:(NSUInteger)tapsRequired {
    
    UITapGestureRecognizer *tap;
    NSArray *gestureRecognizers = [self.gestureRecognizers copy];
    for (tap in gestureRecognizers) {
        if ([tap isKindOfClass:[UITapGestureRecognizer class]] &&
            tap.numberOfTapsRequired == tapsRequired) {
            // same recognizer, add/reset target
            [tap removeTarget:target action:selector];
            [tap addTarget:target action:selector];
            return ;
        }
    }
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:selector];
    tap.numberOfTapsRequired = tapsRequired;
    [self addGestureRecognizer:tap];
    [self setUserInteractionEnabled:YES];
}

- (void)addClickTarget:(nullable id)target action:(nullable SEL)selector {
    
    [self addTapTarget:target action:selector count:1];
}

- (void)addDoubleClickTarget:(nullable id)target action:(nullable SEL)selector {
    
    [self addTapTarget:target action:selector count:2];
}

@end
