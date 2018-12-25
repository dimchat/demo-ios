//
//  RegisterViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "Facebook.h"

#import "RegisterViewController.h"

@interface RegisterViewController () {
    
    NSMutableArray<DIMRegisterInfo *> *_registerInfos;
}

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _registerInfos = [[NSMutableArray alloc] init];
}

- (void)_addRegisterInfo:(DIMRegisterInfo *)info {
    [_registerInfos addObject:info];
    [self.accountsTableView reloadData];
}

- (void)_generateWithParameters:(NSDictionary *)parameters {
    NSString *nickname = [parameters objectForKey:@"nickname"];
    NSString *username = [parameters objectForKey:@"username"];
    NSNumber *count = [parameters objectForKey:@"count"];
    NSInteger cnt = count.integerValue;
    if (cnt < 1) {
        cnt = 10;
    }
    
    DIMRegisterInfo *info;
    DIMPrivateKey *SK;
    
    for (NSInteger index = 0; index < cnt; ++index) {
        SK = [[DIMPrivateKey alloc] init];
        info = [DIMUser registerWithName:username privateKey:SK publicKey:nil];
        info.user.name = nickname;
        
        NSLog(@"generated register info: %@", info);
        [self performSelectorOnMainThread:@selector(_addRegisterInfo:)
                               withObject:info
                            waitUntilDone:NO];
    }
}

- (IBAction)generateAccounts:(id)senderObject {
    NSString *nickname = _nicknameTextField.text;
    NSString *username = _usernameTextField.text;
    
    if (nickname.length == 0 || username.length == 0) {
        NSLog(@"nickname & username cannot be empty");
        return;
    }
    // hide keyboard
    [self.view endEditing:YES];
    
    NSLog(@"generate with %@(%@)", username, nickname);
    
    [_registerInfos removeAllObjects];
    [_accountsTableView reloadData];
    
    NSDictionary *params = @{
                             @"nickname" : nickname,
                             @"username" : username,
                             };
    [self performSelectorInBackground:@selector(_generateWithParameters:)
                           withObject:params];
}

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC {
    [super unwindForSegue:unwindSegue towardsViewController:subsequentVC];
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //#warning Incomplete implementation, return the number of rows
    
    return [_registerInfos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RegisterInfoCell" forIndexPath:indexPath];
    
    //NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    // Configure the cell...
    DIMRegisterInfo *info = [_registerInfos objectAtIndex:row];
    DIMUser *user = info.user;
    
    cell.textLabel.text = account_title(user);
    cell.detailTextLabel.text = user.ID;
    
    return cell;
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
