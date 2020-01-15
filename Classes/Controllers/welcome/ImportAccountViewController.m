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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"title") style:UIBarButtonItemStylePlain target:self action:@selector(didPressSaveButton:)];
    self.view.backgroundColor = [UIColor colorNamed:@"ViewBackgroundColor"];
    
    [self.accountTextView becomeFirstResponder];
}

-(void)didPressSaveButton:(id)sender{
    
//    NSString *jsonString = self.accountTextView.text;
//
//    if(jsonString == nil || jsonString.length == 0){
//        [self showMessage:NSLocalizedString(@"Please input your account info", nil)
//                withTitle:NSLocalizedString(@"Error!", nil)];
//        return;
//    }
//
//    Class nativeJsonParser = NSClassFromString(@"NSJSONSerialization");
//    NSError *error;
//    NSDictionary *returnValue = [nativeJsonParser JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
//    NSString *username = [returnValue objectForKey:@"username"];
//    NSString *nickname = [returnValue objectForKey:@"nickname"];
    
    NSString *privateKey = self.accountTextView.text;
    NSMutableDictionary *returnValue = [[NSMutableDictionary alloc] init];
    [returnValue setObject:privateKey forKey:@"data"];
    [returnValue setObject:@"RSA" forKey:@"algorithm"];

    NSString *username = @"dim";
    NSString *nickname = @"moonfunjohn";
    
    NSUInteger version = MKMMetaDefaultVersion;
    
    if([returnValue objectForKey:@"version"] != nil){
        version = [[returnValue objectForKey:@"version"] unsignedIntegerValue];
    }
    
    // 1. generate private key
    DIMPrivateKey *SK = MKMPrivateKeyFromDictionary(returnValue);
    // 2. generate meta
    DIMMeta *meta = MKMMetaGenerate(version, SK, username);
    // 3. generate ID
    DIMID *ID = [meta generateID:MKMNetwork_Main];
    
    Client *client = [Client sharedInstance];
    if (![client importUser:ID meta:meta privateKey:SK]) {

        [self showMessage:NSLocalizedString(@"Failed to import user.", nil)
                withTitle:NSLocalizedString(@"Error!", nil)];
    } else {
        
        //Get contacts from server
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger queryContacts];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
