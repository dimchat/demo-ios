//
//  UIView+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/7.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Gesture)

// onClick:(UITapGestureRecognizer *)
- (void)addClickTarget:(nullable id)target action:(nullable SEL)selector;

// onDoubleClick:(UITapGestureRecognizer *)
- (void)addDoubleClickTarget:(nullable id)target action:(nullable SEL)selector;

@end

NS_ASSUME_NONNULL_END
