//
//  AccountEditViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "NSObject+JsON.h"

#import "Client.h"

#import "AccountEditViewController.h"

@interface AccountEditViewController ()

@end

@implementation AccountEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    NSString *name = user.name;
    const DIMID *ID = user.ID;
    const DIMMeta *meta = MKMMetaForID(ID);
    DIMPrivateKey *SK = user.privateKey;
    
    _fullnameTextField.text = name;
    _usernameTextField.text = (NSString *)ID;
    _metaTextView.text = [meta jsonString];
    _privateKeyTextView.text = [SK jsonString];
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
