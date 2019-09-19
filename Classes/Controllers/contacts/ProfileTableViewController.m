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
#import "NSNotificationCenter+Extension.h"

#import "UIStoryboardSegue+Extension.h"
#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"

#import "Facebook.h"
#import "Client.h"

#import "User.h"

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
    
    self.title = user_title(_contact);
    
    _profile = DIMProfileForID(_contact);
    
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
            
            // avatar
            CGRect avatarFrame = avatarImageView.frame;
            UIImage *image = [DIMProfileForID(_contact) avatarImageWithSize:avatarFrame.size];
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
            cell.detailTextLabel.text = _contact.name;
        } else if (row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Address", nil);
            cell.detailTextLabel.text = (NSString *)_contact.address;
        } else if (row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Search No.", nil);
            cell.detailTextLabel.text = search_number(_contact.number);
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
        DIMLocalUser *user = [Client sharedInstance].currentUser;
        if ([user existsContact:_contact]) {
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSLog(@"contact: %@", _contact);
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = client.currentUser;
    
    if ([segue.identifier isEqualToString:@"startChat"]) {
        
        DIMConversation *convers = DIMConversationWithID(_contact);
        
        ChatViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = convers;
        
    } else if ([segue.identifier isEqualToString:@"addContact"]) {
        
        // send meta & profile first as handshake
        DIMMeta *meta = DIMMetaForID(user.ID);
        DIMProfile *profile = user.profile;
        DIMCommand *cmd;
        if (profile) {
            cmd = [[DIMProfileCommand alloc] initWithID:user.ID
                                                   meta:meta
                                                profile:profile];
        } else {
            cmd = [[DIMMetaCommand alloc] initWithID:user.ID
                                                meta:meta];
        }
        [client sendContent:cmd to:_contact];
        
        // add to contacts
        [[DIMFacebook sharedInstance] user:user addContact:_contact];
        NSLog(@"contact %@ added to user %@", _contact, user);
        [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];

        DIMConversation *convers = DIMConversationWithID(_contact);
        
        ChatViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = convers;
        
        // refresh button 'Add Contact' to 'Send Message'
        [self.tableView reloadData];
    }
}

@end
