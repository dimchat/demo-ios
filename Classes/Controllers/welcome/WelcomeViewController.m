//
//  WelcomeViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/9.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "UIButton+Extension.h"
#import "UIViewController+Extension.h"

#import "DIMGlobalVariable.h"

#import "Client.h"
#import "ImportAccountViewController.h"
#import "RegisterViewController.h"
#import "WebViewController.h"

#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@property(nonatomic, strong) UIButton *agreeButton;
@property(nonatomic, strong) UIImageView *logoImageView;

@end

@implementation WelcomeViewController

-(void)loadView{
    
    [super loadView];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    self.view.backgroundColor = [UIColor colorNamed:@"ViewBackgroundColor"];
    
    CGFloat width = 128.0;
    CGFloat height = 128.0;
    CGFloat x = (self.view.bounds.size.width - width) / 2.0;
    CGFloat y = 150.0;
    
    if([UIScreen mainScreen].bounds.size.width == 320.0){
        y = 50.0;
    }
    
    self.logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DimLogo"]];
    self.logoImageView.frame = CGRectMake(x, y, width, height);
    [self.logoImageView roundedCorner];
    [self.view addSubview:self.logoImageView];
    
    x = 10.0;
    y = y + height + 150.0;
    height = 40.0;
    width = self.view.bounds.size.width - x * 2;
    
    if([UIScreen mainScreen].bounds.size.width == 320.0){
        y = y - 100.0;
        height = 70.0;
    }
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    titleLabel.text = NSLocalizedString(@"Thanks for using DIM Chat", @"title");
    titleLabel.font = [UIFont boldSystemFontOfSize:28.0];
    titleLabel.numberOfLines = 2;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    y = y + height + 10.0;
    UILabel *agreementLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    agreementLabel.text = NSLocalizedString(@"Please read the privacy policy, click \"Agree and Continue\" to accept the agreement.", @"title");
    agreementLabel.font = [UIFont systemFontOfSize:14.0];
    agreementLabel.numberOfLines = 2;
    agreementLabel.textColor = [UIColor grayColor];
    agreementLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:agreementLabel];
    
    UIButton *agreementButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [agreementButton addTarget:self action:@selector(didPressAgreementButton:) forControlEvents:UIControlEventTouchUpInside];
    agreementButton.frame = agreementLabel.frame;
    [self.view addSubview:agreementButton];
    
    y = y + height + 30.0;
    height = 44.0;
    x = 35.0;
    width = self.view.bounds.size.width - x * 2.0;
    
    self.agreeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.agreeButton.frame = CGRectMake(x, y, width, height);
    [self.agreeButton setTitle:NSLocalizedString(@"Agree and Continue", @"title") forState:UIControlStateNormal];
    self.agreeButton.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    [self.agreeButton addTarget:self action:@selector(didPressRegisterButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.agreeButton];
}

- (void)didPressRegisterButton:(id)sender {
    
    RegisterViewController *registerController = [[RegisterViewController alloc] init];
    [self.navigationController pushViewController:registerController animated:YES];
}

- (void)didPressImportButton:(id)sender {
    
    ImportAccountViewController *controller = [[ImportAccountViewController alloc] initWithNibName:@"ImportAccountViewController" bundle:nil];
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)didPressAgreementButton:(id)sender{
    
    Client *client = [DIMGlobal terminal];
    NSString *urlString = client.termsAPI;
    WebViewController *web = [[WebViewController alloc] init];
    web.url = [NSURL URLWithString:urlString];
    web.title = NSLocalizedString(@"Terms", nil);
    [self.navigationController pushViewController:web animated:YES];
}

@end
