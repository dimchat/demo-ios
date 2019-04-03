//
//  UIImage+Extension.h
//  DIMClient
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Extension)

+ (nullable UIImage *)imageWithURLString:(const NSString *)urlString;

- (UIImage *)thumbnail;

- (NSData *)jpegData;
- (NSData *)pngData;

#pragma mark Text

+ (nullable UIImage *)imageWithText:(const NSString *)text size:(const CGSize)size;
+ (nullable UIImage *)imageWithText:(const NSString *)text
                               size:(const CGSize)size
                              color:(nullable UIColor *)textColor
                    backgroundColor:(nullable UIColor *)bgColor;
+ (nullable UIImage *)imageWithText:(const NSString *)text
                               size:(const CGSize)size
                              color:(nullable UIColor *)textColor
                    backgroundImage:(nullable UIImage *)bgImage;

#pragma mark Tiled Images

+ (UIImage *)tiledImages:(NSArray<UIImage *> *)images size:(const CGSize)size;
+ (UIImage *)tiledImages:(NSArray<UIImage *> *)images
                    size:(const CGSize)size
         backgroundColor:(nullable UIColor *)bgColor;

- (UIImage *)resizableImage;

@end

NS_ASSUME_NONNULL_END
