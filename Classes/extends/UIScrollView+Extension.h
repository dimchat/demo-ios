//
//  UIScrollView+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/17.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (Extension)

- (void)scrollsToBottom:(BOOL)animated;
- (void)scrollsToBottom; // without animated

@end

NS_ASSUME_NONNULL_END
