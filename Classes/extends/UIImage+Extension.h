//
//  UIImage+Extension.h
//  DIMClient
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define UIImage_JPEGCompressionQuality_Photo     0.5
#define UIImage_JPEGCompressionQuality_Thumbnail 0

@interface UIImage (Data)

- (NSData *)jpegDataWithQuality:(CGFloat)compressionQuality;
- (NSData *)pngData;

@end

@interface UIImage (Resize)

- (UIImage *)resize:(CGSize)newSize;
- (UIImage *)aspectFill:(CGSize)maxSize;
- (UIImage *)aspectFit:(CGSize)maxSize;
- (UIImage *)thumbnail;

@end

@interface UIImage (Text)

+ (nullable UIImage *)imageWithText:(NSString *)text size:(const CGSize)size;
+ (nullable UIImage *)imageWithText:(NSString *)text
                               size:(const CGSize)size
                              color:(nullable UIColor *)textColor
                    backgroundColor:(nullable UIColor *)bgColor;
+ (nullable UIImage *)imageWithText:(NSString *)text
                               size:(const CGSize)size
                              color:(nullable UIColor *)textColor
                    backgroundImage:(nullable UIImage *)bgImage;

@end

@interface UIImage (Tiled)

+ (UIImage *)tiledImages:(NSArray<UIImage *> *)images size:(const CGSize)size;
+ (UIImage *)tiledImages:(NSArray<UIImage *> *)images
                    size:(const CGSize)size
         backgroundColor:(nullable UIColor *)bgColor;

@end

NS_ASSUME_NONNULL_END
