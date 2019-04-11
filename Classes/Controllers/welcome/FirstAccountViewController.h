//
//  FirstAccountViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/9.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FirstAccountViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *trayView;

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;

@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (strong, nonatomic) NSString *nickname;

- (IBAction)onUsernameEditExit:(UITextField *)sender;
- (IBAction)onUsernameEditEnd:(UITextField *)sender;

- (IBAction)onRefreshClick:(UIButton *)sender;
- (IBAction)onStartClick:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
