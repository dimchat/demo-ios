//
//  UIView+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/7.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)

- (void)roundedCorner {
//    CGRect rect = self.bounds;
//    UIBezierPath *maskPath;
//    maskPath = [UIBezierPath bezierPathWithRoundedRect:rect
//                                     byRoundingCorners:UIRectCornerAllCorners
//                                           cornerRadii:CGSizeMake(10, 10)];
//    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
//    maskLayer.frame = rect;
//    maskLayer.path = maskPath.CGPath;
//    self.layer.mask = maskLayer;
    self.layer.cornerRadius = 10;
    self.layer.masksToBounds = YES;
}

- (nullable __kindof UIViewController *)controller {
    UIResponder *responder = self.nextResponder;
    for (; responder != nil; responder = responder.nextResponder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

@end

@implementation UIView (Gesture)

- (UITapGestureRecognizer *)tapGestureRecognizerWithTarget:(nullable id)target
                                                    action:(nullable SEL)selector
                                      numberOfTapsRequired:(NSUInteger)tapsRequired {
    NSAssert(tapsRequired > 0, @"taps required must more than ZERO");
    UITapGestureRecognizer *tapGestureRecognizer = nil;
    
    // check duplicated recognizer
    NSArray *gestureRecognizers = [self.gestureRecognizers copy];
    UITapGestureRecognizer *tap;
    for (tap in gestureRecognizers) {
        if (![tap isKindOfClass:[UITapGestureRecognizer class]]) {
            // not a tap gesture recognizer
            continue;
        }
        if (tap.numberOfTapsRequired == tapsRequired) {
            // same recognizer found, reuse it
            [tap removeTarget:target action:selector];
            [tap addTarget:target action:selector];
            tapGestureRecognizer = tap;
        }
    }
    
    if (tapGestureRecognizer == nil) {
        // create a new one
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:target action:selector];
        tapGestureRecognizer.numberOfTapsRequired = tapsRequired;
        [self addGestureRecognizer:tapGestureRecognizer];
        [self setUserInteractionEnabled:YES];
    }
    
    // update relationships
    for (tap in gestureRecognizers) {
        if (![tap isKindOfClass:[UITapGestureRecognizer class]]) {
            // not a tap gesture recognizer
            continue;
        }
        // the tap gesture recognizer with less taps required
        // must depends on the failure of those that required more
        if (tap.numberOfTapsRequired < tapsRequired) {
            [tap requireGestureRecognizerToFail:tapGestureRecognizer];
        } else if (tap.numberOfTapsRequired > tapsRequired) {
            [tapGestureRecognizer requireGestureRecognizerToFail:tap];
        }
    }
    
    return tapGestureRecognizer;
}

- (UITapGestureRecognizer *)addClickTarget:(nullable id)target
                                    action:(nullable SEL)selector {
    UITapGestureRecognizer *tap;
    tap = [self tapGestureRecognizerWithTarget:target
                                        action:selector
                          numberOfTapsRequired:1];
    return tap;
}

- (UITapGestureRecognizer *)addDoubleClickTarget:(nullable id)target
                                          action:(nullable SEL)selector {
    UITapGestureRecognizer *tap;
    tap = [self tapGestureRecognizerWithTarget:target
                                        action:selector
                          numberOfTapsRequired:2];
    return tap;
}

@end
