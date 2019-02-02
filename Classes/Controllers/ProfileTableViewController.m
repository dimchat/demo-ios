//
//  ProfileTableViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSData+Crypto.h"

#import "Facebook.h"
#import "Client+Ext.h"

#import "ChatViewController.h"

#import "ProfileTableViewController.h"

@interface ProfileTableViewController ()

@end

@implementation ProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _nameLabel.text = account_title(_account);
    _descLabel.text = _account.ID;
    
    DIMID *ID = _account.ID;
    DIMMeta *meta = MKMMetaForID(ID);
    
    _seedLabel.text = ID.name;
    _addressLabel.text = ID.address;
    _numberLabel.text = search_number(ID.number);
    _fingerprintLabel.text = [meta.fingerprint base64Encode];
    
    DIMAccountProfile *profile = (DIMAccountProfile *)MKMProfileForID(ID);
    
    _localityLabel.text = [profile objectForKey:@"locality"];
    _nicknameLabel.text = profile.name;
    _avatarLabel.text = profile.avatar;
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 4;
//}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    
//    if (section == 0) {
//        return 1;
//    }
//    if (section == 3) {
//        return 1;
//    }
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
    
    if ([segue.identifier isEqualToString:@"startChat"]) {
        
        DIMID *ID = _account.ID;
        NSLog(@"contact: %@", ID);
        DIMConversation *convers = DIMConversationWithID(ID);
        
        ChatViewController *chatVC = segue.destinationViewController;
        if (![chatVC isKindOfClass:[ChatViewController class]]) {
            chatVC = (ChatViewController *)[(UINavigationController *)chatVC visibleViewController];
        }
        chatVC.conversation = convers;
    }
}

@end
