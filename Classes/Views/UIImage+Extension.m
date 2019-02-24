//
//  UIImage+Extension.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)

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
