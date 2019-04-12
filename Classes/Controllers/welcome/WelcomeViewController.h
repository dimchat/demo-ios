//
//  WelcomeViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/9.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIButton+Extension.h"

NS_ASSUME_NONNULL_BEGIN

@interface WelcomeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *trayView;

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;
@property (weak, nonatomic) IBOutlet SwitchButton *agreedButton;

@property (weak, nonatomic) IBOutlet UIButton *nextButton;

- (IBAction)onNicknameEditExit:(UITextField *)sender;

@end

NS_ASSUME_NONNULL_END
