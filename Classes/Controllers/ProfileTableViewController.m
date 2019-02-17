//
//  ProfileTableViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"
#import "NSData+Crypto.h"

#import "Station+Handler.h"
#import "User.h"
#import "Facebook.h"

#import "ChatViewController.h"

#import "ProfileTableViewController.h"

@interface ProfileTableViewController () {
    
    DIMProfile *_profile;
}

@end

@implementation ProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = account_title(_account);
    
    _profile = MKMProfileForID(_account.ID);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 3;
    }
    if (section == 1) {
        return [_profile.allKeys count];
    }
    if (section == 2) {
        return 1;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"ID";
    }
    if (section == 1) {
        return @"Profiles";
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    // Configure the cell...
    if (section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"IDCell" forIndexPath:indexPath];
        if (row == 0) {
            cell.textLabel.text = @"Username";
            cell.detailTextLabel.text = _account.ID.name;
        } else if (row == 1) {
            cell.textLabel.text = @"Address";
            cell.detailTextLabel.text = _account.ID.address;
        } else if (row == 2) {
            cell.textLabel.text = @"Number";
            cell.detailTextLabel.text = search_number(_account.ID.number);
        }
        return cell;
    }
    if (section == 1) {
        NSString *key = [_profile.allKeys objectAtIndex:row];
        id value = [_profile objectForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            value = [value jsonString];
        }
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell" forIndexPath:indexPath];
        cell.textLabel.text = key;
        cell.detailTextLabel.text = value;
        return cell;
    }
    if (section == 2) {
        DIMUser *user = [DIMClient sharedInstance].currentUser;
        if ([user.contacts containsObject:_account.ID]) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendCell" forIndexPath:indexPath];
        }
        
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSLog(@"contact: %@", _account.ID);
    
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    Station *server = (Station *)client.currentStation;
    
    if ([segue.identifier isEqualToString:@"startChat"]) {
        
        DIMConversation *convers = DIMConversationWithID(_account.ID);
        
        ChatViewController *chatVC = segue.destinationViewController;
        if (![chatVC isKindOfClass:[ChatViewController class]]) {
            chatVC = (ChatViewController *)[(UINavigationController *)chatVC visibleViewController];
        }
        chatVC.conversation = convers;
        
    } else if ([segue.identifier isEqualToString:@"addContact"]) {
        
        // send meta & profile first as handshake
        DIMMeta *meta = MKMMetaForID(user.ID);
        DIMProfile *profile = MKMProfileForID(user.ID);
        DIMCommand *cmd;
        if (profile) {
            cmd = [[DIMProfileCommand alloc] initWithID:user.ID
                                                   meta:meta
                                             privateKey:user.privateKey
                                                profile:profile];
        } else {
            cmd = [[DIMMetaCommand alloc] initWithID:user.ID
                                                meta:meta];
        }
        [server sendContent:cmd to:_account.ID];
        
        // add to contacts
        Facebook *facebook = [Facebook sharedInstance];
        [facebook addContact:_account.ID user:user];
        NSLog(@"contact %@ added to user %@", _account, user);
        
        DIMConversation *convers = DIMConversationWithID(_account.ID);
        
        ChatViewController *chatVC = segue.destinationViewController;
        if (![chatVC isKindOfClass:[ChatViewController class]]) {
            chatVC = (ChatViewController *)[(UINavigationController *)chatVC visibleViewController];
        }
        chatVC.conversation = convers;
        
    }
}

@end
