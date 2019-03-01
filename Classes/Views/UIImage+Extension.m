//
//  UIImage+Extension.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)

+ (UIImage *)imageWithText:(NSString *)text size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    
    CGFloat fontSize = MIN(size.width, size.height) -10;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIColor *color = [UIColor whiteColor];
    NSDictionary *attributes = @{NSFontAttributeName:font,
                                 NSForegroundColorAttributeName:color,
                                 };
    CGRect rect = CGRectMake(5, 0, size.width, size.height);
    [text drawInRect:rect withAttributes:attributes];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)resizableImage {
    CGSize size = self.size;
    CGFloat width = size.width;
    CGFloat height = size.height;
    /* CGFloat top, CGFloat left, CGFloat bottom, CGFloat right */
    UIEdgeInsets insets = UIEdgeInsetsMake(height * 0.75, width * 0.75,
                                           height * 0.75 + 1, width * 0.75 + 1);
    return [self resizableImageWithCapInsets:insets];
}

@end
