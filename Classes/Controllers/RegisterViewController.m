//
//  RegisterViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIViewController+Extension.h"
#import "UIImageView+Extension.h"

#import "User.h"
#import "Client.h"
#import "Facebook+Register.h"

#import "RegisterViewController.h"

@interface RegisterViewController () {
    
    NSMutableArray<NSDictionary *> *_registerInfos;
}

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [_avatarImageView setText:@"Đ"];
    
    _registerInfos = [[NSMutableArray alloc] init];
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    if (!user) {
        [_doneButton setEnabled:NO];
    }
}

- (void)_generateWithParameters:(NSDictionary *)parameters {
    NSString *nickname = [parameters objectForKey:@"nickname"];
    NSString *username = [parameters objectForKey:@"username"];
    NSNumber *count = [parameters objectForKey:@"count"];
    NSInteger cnt = count.integerValue;
    if (cnt < 1) {
        cnt = 20;
    }
    
    Facebook *facebook = [Facebook sharedInstance];
    
    NSDictionary *info;
    DIMPrivateKey *SK;
    const DIMMeta *meta;
    const DIMID *ID;
    DIMUser *user;
    
    for (NSInteger index = 0; index < cnt; ++index) {
        // 1. generate private key
        SK = [[DIMPrivateKey alloc] init];
        // 2. generate meta
        meta = [[DIMMeta alloc] initWithSeed:username
                                  privateKey:SK
                                   publicKey:nil
                                     version:MKMMetaDefaultVersion];
        // 3. generate ID
        ID = [meta buildIDWithNetworkID:MKMNetwork_Main];
        // 4. create user
        user = [[DIMUser alloc] initWithID:ID];
        user.dataSource = facebook;
        
        // add register info
        info = @{@"ID": ID,
                 @"meta": meta,
                 @"user": user,
                 @"privateKey": SK,
                 @"nickname": nickname,
                 };
        
        NSLog(@"generated register info: %@", info);
        [_registerInfos addObject:info];
        
        // refresh table
        [self.accountsTableView performSelectorOnMainThread:@selector(reloadData)
                                                 withObject:nil
                                              waitUntilDone:NO];
    }
}

- (IBAction)changeNickname:(UITextField *)sender {
    NSString *nickname = _nicknameTextField.text;
    if (nickname.length > 0) {
        NSString *text = [nickname substringToIndex:1];
        [_avatarImageView setText:text];
    }
}

- (IBAction)generateAccounts:(id)senderObject {
    NSString *nickname = _nicknameTextField.text;
    NSString *username = _usernameTextField.text;
    
    // check nickname
    if (nickname.length == 0) {
        [self showMessage:@"Nickname cannot be empty" withTitle:@"Nickname Error"];
        [_nicknameTextField becomeFirstResponder];
        return ;
    }
    // check username
    if (username.length == 0) {
        [self showMessage:@"Username cannot be empty" withTitle:@"Username Error"];
        [_usernameTextField becomeFirstResponder];
        return ;
    } else if (!check_username(username)) {
        NSString *msg = @"Username must be composed by characters: 'A'-'Z', 'a'-'z', '0'-'9', '-', '_', '.'";
        [self showMessage:msg withTitle:@"Username Error"];
        [_usernameTextField becomeFirstResponder];
        return ;
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
    NSDictionary *info = [_registerInfos objectAtIndex:row];
    NSString *nickname = [info objectForKey:@"nickname"];
    DIMUser *user = [info objectForKey:@"user"];
    NSString *title =  [NSString stringWithFormat:@"%@ (%@)", nickname, search_number(user.number)];
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = (NSString *)user.ID;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    NSDictionary *info = [_registerInfos objectAtIndex:row];
    
    NSLog(@"row: %ld, saving info: %@", row, info);
    
    DIMID *ID = [info objectForKey:@"ID"];
    DIMMeta *meta = [info objectForKey:@"meta"];
    DIMUser *user = [info objectForKey:@"user"];
    DIMPrivateKey *SK = [info objectForKey:@"privateKey"];
    NSString *nickname = _nicknameTextField.text;
    
    NSString *title = @"New Account";
    NSString *message = [NSString stringWithFormat:@"%@ (%@)", nickname, search_number(ID.number)];
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        Client *client = [Client sharedInstance];
        Facebook *facebook = [Facebook sharedInstance];
        if ([facebook saveMeta:meta privateKey:SK forID:ID]) {
            client.currentUser = user;
        }
        
        // save fullname in profile
        DIMProfile *profile = [[DIMProfile alloc] initWithID:ID];
        [profile setName:nickname];
        [facebook saveProfile:profile forEntityID:ID];
        
        // post notice
        [NSNotificationCenter postNotificationName:kNotificationName_UsersUpdated object:self];
        
        [self->_doneButton setEnabled:YES];
    };
    
    [self showMessage:message
            withTitle:title
        cancelHandler:nil
          cacelButton:@"Cancel"
       defaultHandler:handler
        defaultButton:@"Save"];
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
