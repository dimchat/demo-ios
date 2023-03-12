//
//  UIImageView+Extension.m
//  DIMP
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImage+Extension.h"

#import "UIImageView+Extension.h"

@implementation UIImageView (Text)

- (void)setText:(NSString *)text {
    [self setText:text color:nil backgroundColor:nil];
}

- (void)setText:(NSString *)text color:(nullable UIColor *)textColor backgroundColor:(nullable UIColor *)bgColor {
    CGSize size = self.bounds.size;
    UIImage *image = [UIImage imageWithText:text size:size color:textColor backgroundColor:bgColor];
    [self setImage:image];
}

- (void)setText:(NSString *)text color:(UIColor *)textColor backgroundImage:(UIImage *)backgroundImage {
    
    CGSize size = self.bounds.size;
    UIImage *image = [UIImage imageWithText:text size:size color:textColor backgroundImage:backgroundImage];
    [self setImage:image];
}

@end
