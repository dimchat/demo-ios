//
//  UIColor+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/26.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Hex)

+ (UIColor *)colorWithHexString:(NSString *)hex;

@end

NS_ASSUME_NONNULL_END
