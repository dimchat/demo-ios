//
//  UIStoryboardSegue+Extension.h
//  DIMClient
//
//  Created by Albert Moky on 2019/3/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIStoryboardSegue (ViewController)

- (UIViewController *)visibleDestinationViewController;

@end

NS_ASSUME_NONNULL_END
