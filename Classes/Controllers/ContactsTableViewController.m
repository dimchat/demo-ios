//
//  ContactsTableViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "Facebook.h"

#import "ProfileTableViewController.h"

#import "ContactsTableViewController.h"

@interface ContactsTableViewController ()

@end

@implementation ContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    Facebook *fb = [Facebook sharedInstance];
    
    switch (section) {
        case 0:
            // Functions
            return 4;
            break;
            
        case 1:
            // Starred Friends
            return 2;
            break;
            
        case 2:
            // Contacts
            return [fb numberOfContactsInUser:user];
            break;
            
        default:
            break;
    }
    
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case 0:
            // Functions
            break;
            
        case 1:
            // Starred Friends
            title = @"⭐️ Starred";
            break;
            
        case 2:
            // Contacts
            title = @"Contacts";
            break;
        default:
            break;
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // fix a bug with UISearchBar
    tableView = self.tableView;
    
    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    NSString *identifier = nil;
    
    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    Facebook *fb = [Facebook sharedInstance];
    
    DIMID *ID = nil;
    DIMAccount *contact = nil;
    
    switch (section) {
        case 0:
            // Functions
            switch (row) {
                case 0:
                    identifier = @"NewFriendsCell";
                    break;
                    
                case 1:
                    identifier = @"GroupChatsCell";
                    break;
                    
                case 2:
                    identifier = @"TagsCell";
                    break;
                    
                case 3:
                    identifier = @"OnlineUsersCell";
                    break;
                    
                default:
                    break;
            }
            cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
            break;
            
        case 1:
            // Starred Friends
            if (row == 0) {
                ID = [DIMID IDWithID:MKM_MONKEY_KING_ID];
            } else {
                ID = [DIMID IDWithID:MKM_IMMORTAL_HULK_ID];
            }
            contact = [fb accountWithID:ID];
            
            identifier = @"ContactCell";
            cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
            cell.textLabel.text = contact.name;
            cell.detailTextLabel.text = contact.ID;
            break;
            
        case 2:
            // Contacts
            ID = [fb user:user contactAtIndex:row];
            contact = [fb accountWithID:ID];
            
            identifier = @"ContactCell";
            cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
            cell.textLabel.text = contact.name;
            cell.detailTextLabel.text = contact.ID;
            break;
            
        default:
            break;
    }
    
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
