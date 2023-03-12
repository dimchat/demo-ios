//
//  UIViewController+Extension.h
//  DIMP
//
//  Created by Albert Moky on 2019/3/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Alert)

-(void)showError:(NSError *)error;

- (void)showMessage:(nullable NSString *)text
          withTitle:(nullable NSString *)title;

- (void)showMessage:(nullable NSString *)text
          withTitle:(nullable NSString *)title
      defaultButton:(nullable NSString *)defaultTitle;

- (void)showMessage:(nullable NSString *)text
          withTitle:(nullable NSString *)title
      cancelHandler:(void (^ _Nullable)(UIAlertAction *action))cancelHandler
     defaultHandler:(void (^ _Nullable)(UIAlertAction *action))okHandler;

- (void)showMessage:(nullable NSString *)text
          withTitle:(nullable NSString *)title
      cancelHandler:(void (^ _Nullable)(UIAlertAction *action))cancelHandler
       cancelButton:(nullable NSString *)cancelTitle
     defaultHandler:(void (^ _Nullable)(UIAlertAction *action))okHandler
      defaultButton:(nullable NSString *)defaultTitle;

@end

NS_ASSUME_NONNULL_END
