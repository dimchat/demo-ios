//
//  UIImageView+Extension.h
//  DIMP
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (Text)

// set image with text
- (void)setText:(NSString *)text;

- (void)setText:(NSString *)text color:(nullable UIColor *)textColor backgroundColor:(nullable UIColor *)bgColor;

- (void)setText:(NSString *)text color:(nullable UIColor *)textColor backgroundImage:(nullable UIColor *)backgroundImage;

@end

NS_ASSUME_NONNULL_END
