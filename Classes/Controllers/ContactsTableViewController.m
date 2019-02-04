//
//  ContactsTableViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "Client+Ext.h"

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
    
    return 1;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (section == 1) {
//        return @"Contacts";
//    }
//    return [super tableView:tableView titleForHeaderInSection:section];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    Facebook *fb = [Facebook sharedInstance];
    
    if (section == 0) {
//        return 1;
//    } else if (section == 1) {
        // Contacts
        return [fb numberOfContactsInUser:user];
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    NSString *identifier = nil;

    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    Facebook *fb = [Facebook sharedInstance];

    DIMID *ID = nil;
    DIMAccount *contact = nil;

    if (section == 0) {
//        identifier = @"OnlineUsersCell";
//        cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
//        return cell;
//    } else if (section == 1) {
        ID = [fb user:user contactAtIndex:row];
        contact = [fb accountWithID:ID];
        identifier = @"ContactCell";
        cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        cell.textLabel.text = account_title(contact);
        cell.detailTextLabel.text = contact.ID;
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

//- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSInteger section = indexPath.section;
//    if (section == 1) {
//        indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
//    }
//    return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSInteger section = indexPath.section;
//    if (section == 1) {
//        indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
//    }
//    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
//}

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
