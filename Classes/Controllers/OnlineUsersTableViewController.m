//
//  OnlineUsersTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "User.h"
#import "Facebook.h"
#import "MessageProcessor+Station.h"

#import "Client.h"
#import "Station+Handler.h"

#import "ProfileTableViewController.h"

#import "OnlineUsersTableViewController.h"

@interface OnlineUsersTableViewController () {
    
    NSMutableArray *_onlineUsers;
}

@end

@implementation OnlineUsersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // 1. load from local cache
    [self loadCacheFile];
    
    // 2. query from the station
    Client *client = [Client sharedInstance];
    Station *server = client.currentStation;
    [server queryOnlineUsers];
    
    // 3. waiting for update
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(reloadData:)
               name:@"OnlineUsersUpdated"
             object:nil];
}

- (void)loadCacheFile {
    Client *client = [Client sharedInstance];
    Station *server = client.currentStation;
    
    NSString *dir = NSTemporaryDirectory();
    NSString *path = [dir stringByAppendingPathComponent:@"online_users.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSArray *users = [NSArray arrayWithContentsOfFile:path];
        _onlineUsers = [[NSMutableArray alloc] initWithCapacity:users.count];
        DIMID *ID;
        DIMPublicKey *PK;
        for (NSString *item in users) {
            ID = [DIMID IDWithID:item];
            PK = MKMPublicKeyForID(ID);
            if (PK) {
                [_onlineUsers addObject:ID];
            } else {
                [server queryMetaForID:ID];
            }
        }
    } else {
        _onlineUsers = nil;
    }
}

- (void)reloadData:(NSNotification *)notification {
    Client *client = [Client sharedInstance];
    Station *server = client.currentStation;
    
    NSArray *users = [notification object];
    NSLog(@"online users: %@", users);
    if ([users count] > 0) {
        _onlineUsers = [[NSMutableArray alloc] initWithCapacity:users.count];
        DIMID *ID;
        DIMPublicKey *PK;
        for (NSString *item in users) {
            ID = [DIMID IDWithID:item];
            PK = MKMPublicKeyForID(ID);
            if (PK) {
                [_onlineUsers addObject:ID];
            } else {
                [server queryMetaForID:ID];
            }
        }
    } else {
        [self loadCacheFile];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    return _onlineUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    
    if ([segue.identifier isEqualToString:@"onlineProfileSegue"]) {
        UITableViewCell *cell = sender;
        DIMID *ID = [DIMID IDWithID:cell.detailTextLabel.text];
        
        ProfileTableViewController *profileTVC = segue.destinationViewController;
        profileTVC.account = MKMAccountWithID(ID);
    }
}

@end
