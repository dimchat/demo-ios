//
//  SearchUsersTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/3.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "User.h"
#import "Facebook.h"
#import "MessageProcessor+Station.h"

#import "Client.h"

#import "ProfileTableViewController.h"

#import "SearchUsersTableViewController.h"

@interface SearchUsersTableViewController () {
    
    NSMutableArray *_users;
    NSMutableArray *_onlineUsers;
}

@end

@implementation SearchUsersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(reloadData:)
               name:@"SearchUsersUpdated"
             object:nil];
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    if (user) {
        // online users
        
        // 1. query from the station
        [client queryOnlineUsers];
        
        // 2. waiting for update
        NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
        [dc addObserver:self
               selector:@selector(reloadData:)
                   name:@"OnlineUsersUpdated"
                 object:nil];
    }
}

- (void)reloadData:(NSNotification *)notification {
    
    NSString *notice = [notification name];
    NSDictionary *info = [notification object];
    NSArray *users = [info objectForKey:@"users"];
    
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    Client *client = [Client sharedInstance];
    
    DIMID *ID;
    DIMMeta *meta;
    DIMPublicKey *PK;
    
    if ([notice isEqualToString:@"OnlineUsersUpdated"]) {
        // online users
        NSLog(@"online users: %@", users);
        
        if (_onlineUsers) {
            [_onlineUsers removeAllObjects];
        } else {
            _onlineUsers = [[NSMutableArray alloc] initWithCapacity:users.count];
        }
        
        for (NSString *item in users) {
            ID = [DIMID IDWithID:item];
            PK = MKMPublicKeyForID(ID);
            if (PK) {
                [_onlineUsers addObject:ID];
            } else {
                [client queryMetaForID:ID];
            }
        }
        
    } else if ([notice isEqualToString:@"SearchUsersUpdated"]) {
        // search users
        
        if (_users) {
            [_users removeAllObjects];
        } else {
            _users = [[NSMutableArray alloc] initWithCapacity:users.count];
        }
        
        for (NSString *item in users) {
            ID = [DIMID IDWithID:item];
            if (!MKMNetwork_IsPerson(ID.type) &&
                !MKMNetwork_IsGroup(ID.type)) {
                // ignore
                continue;
            }
            [_users addObject:ID];
        }
        
        NSDictionary *results = [info objectForKey:@"results"];
        id value;
        for (NSString *key in results) {
            ID = [DIMID IDWithID:key];
            value = [results objectForKey:key];
            if ([value isKindOfClass:[NSDictionary class]]) {
                meta = [DIMMeta metaWithMeta:value];
                [barrack saveMeta:meta forEntityID:ID];
            }
        }
        
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *keywords = searchBar.text;
    NSLog(@"****************** searching %@", keywords);
    
    Client *client = [Client sharedInstance];
    [client searchUsersWithKeywords:keywords];
    
    [searchBar resignFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return _users.count;
    } else if (section == 1) {
        return _onlineUsers.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 1) {
        if (_onlineUsers.count == 1) {
            return @"Online User";
        } else if (_onlineUsers.count > 1) {
            return @"Online Users";
        }
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    if (section == 1) {
        // online users
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
        
        // Configure the cell...
        NSInteger row = indexPath.row;
        NSString *item = [_onlineUsers objectAtIndex:row];
        DIMID *ID = [DIMID IDWithID:item];
        
        DIMAccount *contact = MKMAccountWithID(ID);
        cell.textLabel.text = account_title(contact);
        cell.detailTextLabel.text = contact.ID;
        
        return cell;
    }
    
    tableView = self.tableView;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSInteger row = indexPath.row;
    NSString *item = [_users objectAtIndex:row];
    DIMID *ID = [DIMID IDWithID:item];
    
    DIMAccount *contact = MKMAccountWithID(ID);
    cell.textLabel.text = account_title(contact);
    cell.detailTextLabel.text = contact.ID;
    
    return cell;
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
    
    if ([segue.identifier isEqualToString:@"profileSegue"]) {
        UITableViewCell *cell = sender;
        DIMID *ID = [DIMID IDWithID:cell.detailTextLabel.text];
        
        ProfileTableViewController *profileTVC = segue.destinationViewController;
        profileTVC.account = MKMAccountWithID(ID);
    }
}

@end
