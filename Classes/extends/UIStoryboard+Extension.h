//
//  UIStoryboard+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStoryboard (Identifier)

+ (__kindof UIViewController *)instantiateViewControllerWithIdentifier:(NSString *)identifier storyboardName:(NSString *)name;

+ (__kindof UIViewController *)instantiateInitialViewControllerWithStoryboardName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
