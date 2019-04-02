//
//  UIViewController+Extension.m
//  DIMClient
//
//  Created by Albert Moky on 2019/3/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIViewController+Extension.h"

@implementation UIViewController (Extension)

- (void)showMessage:(nullable NSString *)text withTitle:(nullable NSString *)title {
    
    [self showMessage:text withTitle:title defaultButton:@"OK"];
}

- (void)showMessage:(nullable NSString *)text
          withTitle:(nullable NSString *)title
      defaultButton:(nullable NSString *)defaultTitle {
    
    UIAlertController * alert;
    alert = [UIAlertController alertControllerWithTitle:title
                                                message:text
                                         preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OK;
    OK = [UIAlertAction actionWithTitle:NSLocalizedString(defaultTitle, @"Alert Title")
                                  style:UIAlertActionStyleDefault
                                handler:nil];
    [alert addAction:OK];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showMessage:(nullable NSString *)text
          withTitle:(nullable NSString *)title
      cancelHandler:(void (^)(UIAlertAction *))cancelHandler
     defaultHandler:(void (^)(UIAlertAction *))okHandler {
    
    [self showMessage:text
            withTitle:title
        cancelHandler:cancelHandler
         cancelButton:@"Cancel"
       defaultHandler:okHandler
        defaultButton:@"OK"];
}

- (void)showMessage:(nullable NSString *)text
          withTitle:(nullable NSString *)title
      cancelHandler:(void (^ _Nullable)(UIAlertAction *action))cancelHandler
       cancelButton:(nullable NSString *)cancelTitle
     defaultHandler:(void (^ _Nullable)(UIAlertAction *action))okHandler
      defaultButton:(nullable NSString *)defaultTitle {
    
    UIAlertController * alert;
    alert = [UIAlertController alertControllerWithTitle:title
                                                message:text
                                         preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction;
    cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(cancelTitle, @"Cancel Button")
                                      style:UIAlertActionStyleCancel
                                    handler:cancelHandler];
    UIAlertAction *okAction;
    okAction = [UIAlertAction actionWithTitle:NSLocalizedString(defaultTitle, @"OK Button")
                                        style:UIAlertActionStyleDefault
                                      handler:okHandler];

    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
