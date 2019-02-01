//
//  AccountEditViewController.h
//  DIMClient
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccountEditViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *fullnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextView *metaTextView;
@property (weak, nonatomic) IBOutlet UITextView *privateKeyTextView;

@end

NS_ASSUME_NONNULL_END
