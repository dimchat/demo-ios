//
//  FirstAccountViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/9.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIColor+Extension.h"
#import "UIImage+Extension.h"
#import "UIView+Extension.h"
#import "UIImageView+Extension.h"
#import "UIViewController+Extension.h"

#import "User.h"
#import "Client.h"
#import "Facebook+Register.h"

#import "FirstAccountViewController.h"

@interface FirstAccountViewController ()

@property (strong, nonatomic) DIMPrivateKey *SK;
@property (strong, nonatomic) DIMMeta *meta;
@property (strong, nonatomic) const DIMID *ID;

@end

@implementation FirstAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (_nickname.length > 0) {
        self.title = _nickname;
        CGSize size = _avatarImageView.frame.size;
        NSString *text = [_nickname substringToIndex:1];
        UIColor *textColor = [UIColor whiteColor];
        UIImage *bgImage = [UIImage imageNamed:@"avatar-bg"];
        if (bgImage) {
            _avatarImageView.image = [UIImage imageWithText:text size:size color:textColor backgroundImage:bgImage];
        } else {
            UIColor *bgColor = [UIColor colorWithHexString:@"1F1F0A"];
            _avatarImageView.image = [UIImage imageWithText:text size:size color:textColor backgroundColor:bgColor];
        }
    }
    [_avatarImageView roundedCorner];
    
    //[_refreshButton roundedCorner];
    //[_startButton roundedCorner];
    
    [self.view addClickTarget:self action:@selector(onBackgroundClick:)];
}

- (void)onBackgroundClick:(id)sender {
    
    [_usernameTextField resignFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = _scrollView.frame;
    _scrollView.contentSize = CGSizeMake(rect.size.width, 600);
}

- (void)_generate {
    NSLog(@"refreshing...");
    
    // clear
    _addressLabel.text = @"";
    _numberLabel.text = @"";
    
    _SK = nil;
    _meta = nil;
    _ID = nil;
    
    NSString *username = _usernameTextField.text;
    
    // check username
    if (username.length == 0) {
        NSString *message = @"Username cannot be empty.";
        NSString *title = @"Username Error!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        [_usernameTextField becomeFirstResponder];
        return ;
    } else if (!check_username(username)) {
        NSString *message = @"Username must be composed of letters, digits, underscores, or hyphens.";
        NSString *title = @"Username Error!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        [_usernameTextField becomeFirstResponder];
        return ;
    }
    
    // 1. generate private key
    _SK = [[DIMPrivateKey alloc] init];
    // 2. generate meta
    _meta = [[DIMMeta alloc] initWithVersion:MKMMetaDefaultVersion
                                        seed:username
                                  privateKey:_SK
                                   publicKey:nil];
    // 3. generate ID
    _ID = [_meta buildIDWithNetworkID:MKMNetwork_Main];
    
    _addressLabel.text = (NSString *)_ID.address;
    _numberLabel.text = search_number(_ID.number);
}

- (IBAction)onUsernameEditExit:(UITextField *)sender {
    
    [_usernameTextField resignFirstResponder];
}

- (IBAction)onUsernameEditEnd:(UITextField *)sender {
    
    [self _generate];
}

- (IBAction)onRefreshClick:(UIButton *)sender {
    
    [self _generate];
}

- (IBAction)onStartClick:(UIButton *)sender {
    NSLog(@"start chat");
    
    if (_SK == nil || _meta == nil || _ID == nil) {
        NSString *message = @"Generate account failed.";
        NSString *title = @"Error!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        [_usernameTextField becomeFirstResponder];
        return ;
    }
    
    DIMPrivateKey *SK = _SK;
    DIMMeta *meta = _meta;
    const DIMID *ID = _ID;
    
    NSString *nickname = _nickname;
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        
        Client *client = [Client sharedInstance];
        if (![client saveUser:ID meta:meta privateKey:SK name:nickname]) {
            [self showMessage:NSLocalizedString(@"Failed to create user.", nil)
                    withTitle:NSLocalizedString(@"Error!", nil)];
            return ;
        }
        
        // dismiss the welcome page
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    };
    
    NSString *message = [NSString stringWithFormat:@"%@ (%@)", _nickname, search_number(_ID.number)];
    [self showMessage:message
            withTitle:NSLocalizedString(@"New Account", nil)
        cancelHandler:nil
         cancelButton:NSLocalizedString(@"Cancel", nil)
       defaultHandler:handler
        defaultButton:NSLocalizedString(@"OK", nil)];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
