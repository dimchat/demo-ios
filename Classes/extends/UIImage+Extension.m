//
//  UIImage+Extension.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSString+Extension.h"

#import "UIImage+Extension.h"

@implementation UIImage (Extension)

//+ (nullable UIImage *)imageWithContentsOfURL:(NSURL *)url {
//    NSData *data = [NSData dataWithContentsOfURL:url];
//    if (data) {
//        return [UIImage imageWithData:data];
//    } else {
//        NSLog(@"failed to get image data from: %@", url);
//        return nil;
//    }
//}

- (UIImage *)resizableImage {
    CGSize size = self.size;
    CGFloat x = size.width * 0.75;
    CGFloat y = size.height * 0.75;
    /* CGFloat top, CGFloat left, CGFloat bottom, CGFloat right */
    UIEdgeInsets insets = UIEdgeInsetsMake(y, x, y + 1, x + 1);
    return [self resizableImageWithCapInsets:insets];
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
            //
            break;
        case UIImageOrientationUpMirrored:
            //
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUp:
            //
            break;
        case UIImageOrientationDown:
            //
            break;
        case UIImageOrientationLeft:
            //
            break;
        case UIImageOrientationRight:
            //
            break;
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
    }
    
    return transform;
}

- (UIImage *)thumbnail {
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat maxWidth = MIN(screenSize.width, screenSize.height) / 4;
    if (maxWidth > 120) {
        maxWidth = 120;
    }
    CGSize size = self.size;
    if (maxWidth >= size.width) {
        return self;
    }
    CGFloat ratio = maxWidth / size.width;
    CGSize newSize = CGSizeMake(size.width * ratio, size.height * ratio);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = self.CGImage;
    
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                CGImageGetBitmapInfo(imageRef));
    
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, [self transformForOrientation:newSize]);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationLow);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}

- (NSData *)jpegData {
    return UIImageJPEGRepresentation(self, 1);
}

- (NSData *)pngData {
    return UIImagePNGRepresentation(self);
}

@end

@implementation UIImage (Text)

+ (nullable UIImage *)imageWithText:(const NSString *)text size:(const CGSize)size {
    return [self imageWithText:text size:size color:nil backgroundColor:nil];
}

+ (nullable UIImage *)imageWithText:(const NSString *)text
                               size:(const CGSize)size
                              color:(nullable UIColor *)textColor
                    backgroundColor:(nullable UIColor *)bgColor {
    
    // prepare image contact
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (bgColor) {
        CGContextSetFillColorWithColor(context, bgColor.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }
    
    // calculate font size
    CGFloat fontSize = [UIFont systemFontSize];
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    CGSize textSize = [text sizeWithFont:font maxSize:size];
    CGFloat scale = MIN(size.width / textSize.width,
                        size.height / textSize.height);
    // adjust text font size
    fontSize *= scale;
    font = [UIFont systemFontOfSize:fontSize];
    textSize = [text sizeWithFont:font maxSize:size];
    
    // draw the text in center
    NSDictionary *attr;
    if (textColor) {
        attr = @{NSFontAttributeName:font,
                 NSForegroundColorAttributeName:textColor,
                 };
    } else {
        attr = @{NSFontAttributeName:font,
                 };
    }
    CGRect rect = CGRectMake((size.width - textSize.width) * 0.5,
                             (size.height - textSize.height) * 0.5,
                             size.width, size.height);
    [text drawInRect:rect withAttributes:attr];
    
    // get image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (nullable UIImage *)imageWithText:(const NSString *)text
                               size:(const CGSize)size
                              color:(nullable UIColor *)textColor
                    backgroundImage:(nullable UIImage *)bgImage {
    
    // prepare image contact
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (bgImage) {
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), bgImage.CGImage);
    }
    
    // calculate font size
    CGFloat fontSize = [UIFont systemFontSize];
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    CGSize textSize = [text sizeWithFont:font maxSize:size];
    CGFloat scale = MIN(size.width / textSize.width,
                        size.height / textSize.height);
    // adjust text font size
    fontSize *= scale;
    font = [UIFont systemFontOfSize:fontSize];
    textSize = [text sizeWithFont:font maxSize:size];
    
    // draw the text in center
    NSDictionary *attr;
    if (textColor) {
        attr = @{NSFontAttributeName:font,
                 NSForegroundColorAttributeName:textColor,
                 };
    } else {
        attr = @{NSFontAttributeName:font,
                 };
    }
    CGRect rect = CGRectMake((size.width - textSize.width) * 0.5,
                             (size.height - textSize.height) * 0.5,
                             size.width, size.height);
    [text drawInRect:rect withAttributes:attr];
    
    // get image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@implementation UIImage (Tiled)

+ (UIImage *)tiledImages:(NSArray<UIImage *> *)images size:(const CGSize)size {
    return [self tiledImages:images size:size backgroundColor:nil];
}

#define UIImageTiledDraw(i, kX, kY, dX, dY)                                    \
        do {                                                                   \
            tileImage = [images objectAtIndex:(i)];                            \
            tileRect = CGRectMake(center.x + tileCenter.x * (kX-1) + dX,       \
                                  center.y + tileCenter.y * (kY-1) + dY,       \
                                  tileSize.width, tileSize.height);            \
            [tileImage drawInRect:tileRect];                                   \
        } while (0)                      /* EOF 'UIImageTiledDraw(i, dx, dy)' */

+ (UIImage *)tiledImages:(NSArray<UIImage *> *)images
                    size:(const CGSize)size
         backgroundColor:(nullable UIColor *)bgColor {
    
    // prepare image contact
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (bgColor) {
        CGContextSetFillColorWithColor(context, bgColor.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    }
    
    NSUInteger count = images.count;
    CGSize tileSize;
    if (count > 4) {
        tileSize = CGSizeMake(size.width / 3 - 2, size.height / 3 - 2);
    } else {
        tileSize = CGSizeMake(size.width / 2 - 2, size.height / 2 - 2);
    }
    CGPoint center = CGPointMake(size.width * 0.5, size.height * 0.5);
    CGPoint tileCenter = CGPointMake(tileSize.width * 0.5, tileSize.height * 0.5);
    
    UIImage *tileImage;
    CGRect tileRect;
    switch (count) {
        case 0:
            //NSAssert(false, @"tiled images cannot be empty");
            break;
            
        case 1:
            UIImageTiledDraw(0,  0,  0,  0,  0); // center
            break;
            
        case 2:
            UIImageTiledDraw(0, -1,  0, -1,  0); // left
            UIImageTiledDraw(1,  1,  0,  1,  0); // right
            break;
            
        case 3:
            UIImageTiledDraw(0,  0, -1,  0, -1); // top center
            UIImageTiledDraw(1, -1,  1, -1,  1); // bottom left
            UIImageTiledDraw(2,  1,  1,  1,  1); // bottom right
            break;
            
        case 4:
            UIImageTiledDraw(0, -1, -1, -1, -1); // top left
            UIImageTiledDraw(1,  1, -1,  1, -1); // top right
            UIImageTiledDraw(2, -1,  1, -1,  1); // bottom left
            UIImageTiledDraw(3,  1,  1,  1,  1); // bottom right
            break;
            
        case 5:
            UIImageTiledDraw(0, -1, -1, -1, -1); // top left
            UIImageTiledDraw(1,  1, -1,  1, -1); // top right
            UIImageTiledDraw(2, -2,  1, -3,  1); // bottom left
            UIImageTiledDraw(3,  0,  1,  0,  1); // bottom center
            UIImageTiledDraw(4,  2,  1,  3,  1); // bottom right
            break;
            
        case 6:
            UIImageTiledDraw(0, -2, -1, -3, -1); // top left
            UIImageTiledDraw(1,  0, -1,  0, -1); // top center
            UIImageTiledDraw(2,  2, -1,  3, -1); // top right
            UIImageTiledDraw(3, -2,  1, -3,  1); // bottom left
            UIImageTiledDraw(4,  0,  1,  0,  1); // bottom center
            UIImageTiledDraw(5,  2,  1,  3,  1); // bottom right
            break;
            
        case 7:
            UIImageTiledDraw(0,  0, -2,  0, -3); // top center
            UIImageTiledDraw(1, -2,  0, -3,  0); // middle left
            UIImageTiledDraw(2,  0,  0,  0,  0); // middle center
            UIImageTiledDraw(3,  2,  0,  3,  0); // middle right
            UIImageTiledDraw(4, -2,  2, -3,  3); // bottom left
            UIImageTiledDraw(5,  0,  2,  0,  3); // bottom center
            UIImageTiledDraw(6,  2,  2,  3,  3); // bottom right
            break;
            
        case 8:
            UIImageTiledDraw(0, -1, -2, -1, -3); // top left
            UIImageTiledDraw(1,  1, -2,  1, -3); // top right
            UIImageTiledDraw(2, -2,  0, -3,  0); // middle left
            UIImageTiledDraw(3,  0,  0,  0,  0); // middle center
            UIImageTiledDraw(4,  2,  0,  3,  0); // middle right
            UIImageTiledDraw(5, -2,  2, -3,  3); // bottom left
            UIImageTiledDraw(6,  0,  2,  0,  3); // bottom center
            UIImageTiledDraw(7,  2,  2,  3,  3); // bottom right
            break;
            
        default: // >= 9
            UIImageTiledDraw(0, -2, -2, -3, -3); // top left
            UIImageTiledDraw(1,  0, -2,  0, -3); // top center
            UIImageTiledDraw(2,  2, -2,  3, -3); // top right
            UIImageTiledDraw(3, -2,  0, -3,  0); // middle left
            UIImageTiledDraw(4,  0,  0,  0,  0); // middle center
            UIImageTiledDraw(5,  2,  0,  3,  0); // middle right
            UIImageTiledDraw(6, -2,  2, -3,  3); // bottom left
            UIImageTiledDraw(7,  0,  2,  0,  3); // bottom center
            UIImageTiledDraw(8,  2,  2,  3,  3); // bottom right
            break;
    }
    
    // get image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
