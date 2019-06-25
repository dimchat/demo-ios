//
//  ImportAccountViewController.m
//  Sechat
//
//  Created by moonfunjohn on 2019/6/25.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "ImportAccountViewController.h"
#import "User.h"
#import "Client.h"
#import "Facebook+Register.h"
#import "UIViewController+Extension.h"

@interface ImportAccountViewController ()
@property (strong, nonatomic) IBOutlet UITextView *accountTextView;

@end

@implementation ImportAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.title = NSLocalizedString(@"Import Account", @"title");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didPressSaveButton:)];
    
    [self.accountTextView becomeFirstResponder];
}

-(void)didPressSaveButton:(id)sender{
    
    NSString *jsonString = self.accountTextView.text;
    
    if(jsonString == nil || jsonString.length == 0){
        [self showMessage:NSLocalizedString(@"Please input your account info", nil)
                withTitle:NSLocalizedString(@"Error!", nil)];
        return;
    }
    
    Class nativeJsonParser = NSClassFromString(@"NSJSONSerialization");
    NSDictionary *returnValue = [nativeJsonParser JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    NSString *username = [returnValue objectForKey:@"username"];
    NSString *nickname = [returnValue objectForKey:@"nickname"];
    
    // 1. generate private key
    DIMPrivateKey *SK = MKMPrivateKeyWithAlgorithm(ACAlgorithmRSA);
    // 2. generate meta
    DIMMeta *meta = MKMMetaGenerate(MKMMetaDefaultVersion, SK, username);
    // 3. generate ID
    DIMID *ID = [meta generateID:MKMNetwork_Main];
    
    Client *client = [Client sharedInstance];
    if (![client saveUser:ID meta:meta privateKey:SK name:nickname]) {
        [self showMessage:NSLocalizedString(@"Failed to import user.", nil)
                withTitle:NSLocalizedString(@"Error!", nil)];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
