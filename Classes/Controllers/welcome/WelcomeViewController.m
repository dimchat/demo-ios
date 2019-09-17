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
#import "ImportAccountViewController.h"
#import "RegisterViewController.h"
#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@property(nonatomic, strong) UIButton *registerButton;
@property(nonatomic, strong) UIButton *importButton;
@property(nonatomic, strong) UIImageView *logoImageView;

@end

@implementation WelcomeViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.title = NSLocalizedString(@"Welcome", @"title");
    
    CGFloat height = 44.0;
    CGFloat x = 20.0;
    CGFloat y = self.view.bounds.size.height - height - 50.0;
    CGFloat width = self.view.bounds.size.width - x * 2.0;
    
    self.importButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.importButton.frame = CGRectMake(x, y, width, height);
    [self.importButton setTitle:NSLocalizedString(@"Import", @"title") forState:UIControlStateNormal];
    [self.importButton addTarget:self action:@selector(didPressImportButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.importButton];
    
    y = y - 22.0 - height;
    
    self.registerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.registerButton.frame = CGRectMake(x, y, width, height);
    [self.registerButton setTitle:NSLocalizedString(@"Register", @"title") forState:UIControlStateNormal];
    [self.registerButton addTarget:self action:@selector(didPressRegisterButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.registerButton];
    
    width = 128.0;
    height = 128.0;
    x = (self.view.bounds.size.width - width) / 2.0;
    y = (y - height) / 2.0;
    
    self.logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DimLogo"]];
    self.logoImageView.frame = CGRectMake(x, y, width, height);
    [self.logoImageView roundedCorner];
    [self.view addSubview:self.logoImageView];
}

- (void)didPressRegisterButton:(id)sender {
    
    RegisterViewController *registerController = [[RegisterViewController alloc] init];
    [self.navigationController pushViewController:registerController animated:YES];
}

- (void)didPressImportButton:(id)sender {
    
    ImportAccountViewController *controller = [[ImportAccountViewController alloc] initWithNibName:@"ImportAccountViewController" bundle:nil];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
