//
//  SearchUsersTableViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/3.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "Client+Ext.h"
#import "Facebook.h"
#import "Station.h"

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
    
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    if (user) {
        // online users
        
        // 1. query from the station
        DIMCommand *content = [[DIMCommand alloc] initWithCommand:@"users"];
        Station *station = (Station *)client.currentStation;
        DKDTransceiverCallback callback = ^(const DKDReliableMessage * _Nonnull rMsg, const NSError * _Nullable error) {
            assert(!error);
        };
        DIMTransceiver *trans = [DIMTransceiver sharedInstance];
        [trans sendMessageContent:content
                             from:user.ID
                               to:station.ID
                             time:nil
                         callback:callback];
        
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
    DIMClient *client = [DIMClient sharedInstance];
    Station *station = (Station *)client.currentStation;
    
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
                [station queryMetaForID:ID];
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
        for (NSString *key in results) {
            ID = [DIMID IDWithID:key];
            meta = [DIMMeta metaWithMeta:[results objectForKey:key]];
            [barrack saveMeta:meta forEntityID:ID];
        }
        
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *keywords = searchBar.text;
    NSLog(@"****************** searching %@", keywords);
    
    DIMClient *client = [DIMClient sharedInstance];
    Station *station = (Station *)client.currentStation;
    [station searchUsersWithKeywords:keywords];
    
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
        return @"Online Users";
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
