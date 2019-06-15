//
//  ProfileTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"
#import "NSData+Crypto.h"
#import "NSDate+Timestamp.h"

#import "UIStoryboardSegue+Extension.h"
#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"

#import "Client.h"

#import "User.h"
#import "Facebook+Relationship.h"

#import "ChatViewController.h"

#import "ProfileTableViewController.h"

@interface ProfileTableViewController () {
    
    DIMProfile *_profile;
    NSMutableArray *_keys;
}

@end

#define SECTION_COUNT     4

#define SECTION_AVATAR    0
#define SECTION_ID        1
#define SECTION_PROFILES  2
#define SECTION_FUNCTIONS 3

@implementation ProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = account_title(_account);
    
    _profile = DIMProfileForID(_account.ID);
    
    NSArray *keys = [_profile dataKeys];
    _keys = [[NSMutableArray alloc] initWithCapacity:keys.count];
    for (NSString *key in keys) {
        if ([key isEqualToString:@"ID"] ||
            [key isEqualToString:@"lastTime"]) {
            // ignore them
            continue;
        }
        [_keys addObject:key];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == SECTION_AVATAR) {
        // avatar
        return 1;
    }
    if (section == SECTION_ID) {
        // ID
        return 3;
    }
    if (section == SECTION_PROFILES) {
        // profiles
        return [_keys count];
    }
    if (section == SECTION_FUNCTIONS) {
        // functions
        return 1;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SECTION_ID) {
        // ID
        return NSLocalizedString(@"ID", nil);
    }
    if (section == SECTION_PROFILES) {
        // profiles
        return NSLocalizedString(@"Profiles", nil);
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    // Configure the cell...
    if (section == SECTION_AVATAR) {
        // Avatar
        cell = [tableView dequeueReusableCellWithIdentifier:@"AvatarCell" forIndexPath:indexPath];
        if (row == 0) {
            UIImageView *avatarImageView = nil;
            for (UIImageView *iv in cell.contentView.subviews) {
                if ([iv isKindOfClass:[UIImageView class]]) {
                    avatarImageView = iv;
                    break;
                }
            }
            
            DIMProfile *profile = DIMProfileForID(_account.ID);
            
            // avatar
            CGRect avatarFrame = avatarImageView.frame;
            UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
            if (!image) {
                image = [UIImage imageNamed:@"AppIcon"];
            }
            [avatarImageView setImage:image];
            [avatarImageView roundedCorner];
        }
        return cell;
    }
    if (section == SECTION_ID) {
        // ID
        cell = [tableView dequeueReusableCellWithIdentifier:@"IDCell" forIndexPath:indexPath];
        if (row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Username", nil);
            cell.detailTextLabel.text = _account.ID.name;
        } else if (row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Address", nil);
            cell.detailTextLabel.text = (NSString *)_account.ID.address;
        } else if (row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Search No.", nil);
            cell.detailTextLabel.text = search_number(_account.ID.number);
        }
        return cell;
    }
    if (section == SECTION_PROFILES) {
        // profiles
        NSString *key = [_keys objectAtIndex:row];
        id value = [_profile dataForKey:key];
        if (![value isKindOfClass:[NSString class]]) {
            if ([value isKindOfClass:[NSArray class]]) {
                value = [value componentsJoinedByString:@", "];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                value = [value jsonString];
            } else {
                value = [NSString stringWithFormat:@"%@", value];
            }
        }
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell" forIndexPath:indexPath];
        cell.textLabel.text = key;
        cell.detailTextLabel.text = value;
        return cell;
    }
    if (section == SECTION_FUNCTIONS) {
        // functions
        DIMUser *user = [Client sharedInstance].currentUser;
        if ([user existsContact:_account.ID]) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendCell" forIndexPath:indexPath];
        }
        
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    //NSInteger row = indexPath.row;
    if (section == SECTION_AVATAR) {
        return 160;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
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
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    if ([segue.identifier isEqualToString:@"startChat"]) {
        
        DIMConversation *convers = DIMConversationWithID(_account.ID);
        
        ChatViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = convers;
        
    } else if ([segue.identifier isEqualToString:@"addContact"]) {
        
        // send meta & profile first as handshake
        const DIMMeta *meta = DIMMetaForID(user.ID);
        DIMProfile *profile = DIMProfileForID(user.ID);
        DIMCommand *cmd;
        if (profile) {
            cmd = [[DIMProfileCommand alloc] initWithID:user.ID
                                                   meta:meta
                                                profile:profile];
        } else {
            cmd = [[DIMMetaCommand alloc] initWithID:user.ID
                                                meta:meta];
        }
        [client sendContent:cmd to:_account.ID];
        
        // add to contacts
        Facebook *facebook = [Facebook sharedInstance];
        [facebook user:user addContact:_account.ID];
        NSLog(@"contact %@ added to user %@", _account, user);
        
        DIMConversation *convers = DIMConversationWithID(_account.ID);
        
        ChatViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = convers;
        
        // refresh button 'Add Contact' to 'Send Message'
        [self.tableView reloadData];
    }
}

@end
