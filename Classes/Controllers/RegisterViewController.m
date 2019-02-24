//
//  RegisterViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "User.h"
#import "Client.h"
#import "Facebook+Register.h"

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
        cnt = 20;
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
    
    [self _hideKeyboard];
    
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

- (void)_hideKeyboard {
    [self.view endEditing:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [self _hideKeyboard];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    DIMRegisterInfo *regInfo = [_registerInfos objectAtIndex:row];
    
    NSLog(@"row: %ld, saving info: %@", row, regInfo);
    
    Client *client = [Client sharedInstance];
    
    DIMID *ID = regInfo.ID;
    NSString *message = [NSString stringWithFormat:@"Save user: %@ ?", ID];
    
    NSString *nickname = _nicknameTextField.text;
    
    UIAlertController * alert;
    alert = [UIAlertController alertControllerWithTitle:@"Register"
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel;
    cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                      style:UIAlertActionStyleCancel
                                    handler:nil];
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        Facebook *facebook = [Facebook sharedInstance];
        if ([facebook saveRegisterInfo:regInfo]) {
            client.currentUser = regInfo.user;
        }
        
        // save fullname in profile
        DIMProfile *profile = [[DIMProfile alloc] initWithID:regInfo.ID];
        [profile setName:nickname];
        [facebook saveProfile:profile forID:regInfo.ID];
        
        // post notice
        [client postNotificationName:@"UsersUpdated"];
        NSLog(@"post notification: UsersUpdated");
    };
    
    UIAlertAction *OK;
    OK = [UIAlertAction actionWithTitle:@"OK"
                                  style:UIAlertActionStyleDefault
                                handler:handler];
    
    [alert addAction:cancel];
    [alert addAction:OK];
    [self presentViewController:alert animated:YES completion:nil];
    
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
