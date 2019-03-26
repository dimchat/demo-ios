//
//  UIColor+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/26.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIColor+Extension.h"

static inline char hex_char(char ch) {
    if (ch >= '0' && ch <= '9') {
        return ch - '0';
    }
    if (ch >= 'a' && ch <= 'f') {
        return ch - 'a' + 10;
    }
    if (ch >= 'A' && ch <= 'F') {
        return ch - 'A' + 10;
    }
    return 0;
}

@implementation UIColor (Extension)

+ (UIColor *)colorWithHexString:(NSString *)hex {
    NSAssert(hex.length == 6, @"color string error %@", hex);
    char ch0 = [hex characterAtIndex:0];
    char ch1 = [hex characterAtIndex:1];
    char ch2 = [hex characterAtIndex:2];
    char ch3 = [hex characterAtIndex:3];
    char ch4 = [hex characterAtIndex:4];
    char ch5 = [hex characterAtIndex:5];
    CGFloat r = (hex_char(ch0) * 16 + hex_char(ch1)) / 256.0;
    CGFloat g = (hex_char(ch2) * 16 + hex_char(ch3)) / 256.0;
    CGFloat b = (hex_char(ch4) * 16 + hex_char(ch5)) / 256.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

@end
