//
//  UIButton+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/30.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwitchButton : UIButton

@end

@interface MessageButton : UIButton

@property (strong, nonatomic, nullable) NSString *title;
@property (strong, nonatomic, nullable) NSString *message;

@property (weak, nonatomic) UIViewController *controller;

@end

NS_ASSUME_NONNULL_END
