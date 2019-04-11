//
//  WelcomeViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/9.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIStoryboardSegue+Extension.h"
#import "UIView+Extension.h"
#import "UIViewController+Extension.h"
#import "WebViewController.h"

#import "User.h"
#import "Client.h"

#import "FirstAccountViewController.h"

#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [_logoImageView roundedCorner];
    
    //[_nextButton roundedCorner];
    [self.view addClickTarget:self action:@selector(onBackgroundClick:)];
}

- (void)onBackgroundClick:(id)sender {
    
    [_nicknameTextField resignFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = _scrollView.frame;
    UIEdgeInsets insets = _scrollView.adjustedContentInset;
    
    CGSize vSize = CGSizeMake(rect.size.width - insets.left - insets.right,
                              rect.size.height - insets.top - insets.bottom);
    
    CGSize size = CGSizeMake(320, MAX(vSize.height, 520));
    
    _trayView.frame = CGRectMake((vSize.width - size.width) * 0.5, 0,
                                 size.width, size.height);
    _scrollView.frame = CGRectMake(0, 0,
                                   rect.origin.x + rect.size.width,
                                   rect.origin.y + rect.size.height);
    _scrollView.contentSize = CGSizeMake(size.width, size.height);
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    Client *client = [Client sharedInstance];
    
    if ([segue.identifier isEqualToString:@"terms"]) {
        // show terms
        NSString *urlString = client.termsAPI;
        WebViewController *web = [segue visibleDestinationViewController];
        web.url = [NSURL URLWithString:urlString];
        web.title = NSLocalizedString(@"Terms", nil);
    } else if ([segue.identifier isEqualToString:@"next"]) {
        // next step
        FirstAccountViewController *first = [segue visibleDestinationViewController];
        first.nickname = _nicknameTextField.text;
    }
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
    if ([identifier isEqualToString:@"next"]) {
        // check nickname
        NSString *nickname = _nicknameTextField.text;
        if (nickname.length == 0) {
            NSString *message = @"Nickname cannot be empty.";
            NSString *title = @"Nickname Error!";
            [self showMessage:NSLocalizedString(message, nil)
                    withTitle:NSLocalizedString(title, nil)];
            [_nicknameTextField becomeFirstResponder];
            return NO;
        }
        
        // check agreement
        if (_agreedButton.selected == NO) {
            NSString *title = @"Read the Agreements!";
            NSString *message = @"You must read and agree the user agreements and privacy clauses.";
            [self showMessage:NSLocalizedString(message, nil)
                    withTitle:NSLocalizedString(title, nil)];
            return NO;
        }
    }
    return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
}

@end
