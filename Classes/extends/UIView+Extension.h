//
//  UIView+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/7.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Extension)

- (void)roundedCorner;

@end

@interface UIView (Gesture)

// onClick:(UITapGestureRecognizer *)
- (UITapGestureRecognizer *)addClickTarget:(nullable id)target action:(nullable SEL)selector;

// onDoubleClick:(UITapGestureRecognizer *)
- (UITapGestureRecognizer *)addDoubleClickTarget:(nullable id)target action:(nullable SEL)selector;

@end

NS_ASSUME_NONNULL_END
