//
//  ParticipantsManageTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIImageView+Extension.h"
#import "UIViewController+Extension.h"

#import "User.h"
#import "Facebook+Register.h"
#import "Client.h"

#import "ParticipantManageCell.h"

#import "ParticipantsManageTableViewController.h"

const NSString *kNotificationName_GroupMembersUpdated = @"GroupMembersUpdated";

static inline NSArray<const DIMID *> *group_member_candidates(const DIMGroup *group, const DIMUser *user) {
    const DIMID *founder = group.founder;
    NSArray<const DIMID *> *members = group.members;
    const DIMID *current = user.ID;
    NSArray<const DIMID *> *contacts = user.contacts;
    
    const DIMID *ID;
    NSMutableArray *candidates = [[NSMutableArray alloc] initWithCapacity:(members.count + contacts.count)];
    // add all members (except the founder & current user) as candidates
    for (ID in members) {
        if ([ID isEqual:founder] || [ID isEqual:current]) {
            // move these two account to the tail
            continue;
        }
        if ([candidates containsObject:ID]) {
            continue;
        }
        [candidates addObject:ID];
    }
    // add all contacts (except the founder & current user) as candidates
    for (ID in contacts) {
        if ([ID isEqual:founder] || [ID isEqual:current]) {
            // move these two account to the tail
            continue;
        }
        if ([candidates containsObject:ID]) {
            continue;
        }
        [candidates addObject:ID];
    }
    
    // add current user & founder as candidates
    if (current) {
        [candidates addObject:current];
    }
    if (founder && ![founder isEqual:current]) {
        [candidates addObject:founder];
    }
    return candidates;
}

@interface ParticipantsManageTableViewController () {
    
    DIMGroup *_group;
    const DIMID *_founder;
    NSArray<const DIMID *> *_memberList;
    
    NSArray<const DIMID *> *_candidateList;
    NSMutableArray<const DIMID *> *_selectedList;
}

@end

@implementation ParticipantsManageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [_logoImageView roundedCorner];
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    // 1. group info
    if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        // exists group
        _group = MKMGroupWithID(_conversation.ID);
        _founder = _group.founder;
        // Notice: the group member list will/will not include the founder
        _memberList = _group.members;
        
        // 1.1. logo
        DIMProfile *profile = MKMProfileForID(_group.ID);
        NSString *name = profile.name;
        if (name.length > 0) {
            [_logoImageView setText:[NSString stringWithFormat:@"[%@]", [name substringToIndex:1]]];
        } else {
            [_logoImageView setText:@"[Đ]"];
        }
        
        // 1.2. name
        _nameTextField.text = name;
        
        // 1.3. seed
        _seedTextField.text = _group.ID.name;
        _seedTextField.enabled = NO;
    } else {
        // new group
        _group = nil;
        _founder = user.ID;
        // Notice: the group member list will/will not include the founder
        _memberList = [[NSArray alloc] initWithObjects:_conversation.ID, nil];
        
        // 1.1. logo
        [_logoImageView setText:@"[Đ]"];
        
        // 1.2. name
        _nameTextField.text = @"";
        
        // 1.3. seed
        uint32_t seed = arc4random();
        if (_conversation.ID.name) {
            _seedTextField.text = [NSString stringWithFormat:@"polylogue-%u-%@", seed, _conversation.ID.name];
        } else {
            _seedTextField.text = [NSString stringWithFormat:@"polylogue-%u", seed];
        }
        _seedTextField.enabled = YES;
    }
    
    // 2. candidates
    _candidateList = group_member_candidates(_group, user);
    
    // 3. selected list
    _selectedList = [[NSMutableArray alloc] init];
    [_selectedList addObject:user.ID];
    if (_founder && ![_founder isEqual:user.ID]) {
        [_selectedList addObject:_founder];
    }
    if (!_group && MKMNetwork_IsCommunicator(_conversation.ID.type)) {
        if (![_selectedList containsObject:_conversation.ID]) {
            [_selectedList addObject:_conversation.ID];
        }
    }
    if (_memberList.count > 0) {
        for (const DIMID *item in _memberList) {
            if ([_selectedList containsObject:item]) {
                continue;
            }
            [_selectedList addObject:item];
        }
    }
}

- (IBAction)changeGroupName:(UITextField *)sender {
    NSString *name = sender.text;
    if (name.length > 0) {
        NSString *text = [name substringToIndex:1];
        text = [NSString stringWithFormat:@"[%@]", text];
        [_logoImageView setText:text];
    }
}

- (BOOL)submitGroupInfo {
    Client *client = [Client sharedInstance];
    
    const DIMID *ID = _conversation.ID;
    NSString *seed = _seedTextField.text;
    NSString *name = _nameTextField.text;
    DIMProfile *profile;
//    NSMutableArray<const DIMID *> *members;
    
    if (MKMNetwork_IsGroup(ID.type)) {
        // exists group
        profile = MKMProfileForID(ID);
        if (profile) {
            profile.name = name;
        } else {
            profile = [[DIMProfile alloc] initWithDictionary:@{@"ID":ID,
                                                               @"name":name,
                                                               }];
        }
        BOOL success = [client updateGroupWithID:ID
                                         members:_selectedList
                                         profile:profile];
        if (!success) {
            NSLog(@"failed to update group: %@, %@, %@", ID, _selectedList, profile);
            [self showMessage:[NSString stringWithFormat:@"%@\n%@", name, ID.name] withTitle:@"Update Group Failed"];
            return NO;
        }
        NSLog(@"update group: %@, profile: %@, members: %@", ID, profile, _selectedList);
    } else {
        // new group
        _group = [client createGroupWithSeed:seed
                                     members:_selectedList
                                     profile:@{@"name":name}];
        if (!_group) {
            NSLog(@"failed to create group: %@, %@, %@", seed, _selectedList, name);
            [self showMessage:[NSString stringWithFormat:@"%@\n%@", name, seed] withTitle:@"Create Group Failed"];
            return NO;
        }
        ID = _group.ID;
        profile = [[DIMProfile alloc] initWithDictionary:@{@"ID":ID, @"name":name}];
        NSLog(@"new group: %@, profile: %@, members: %@", ID, profile, _selectedList);
    }
    
    // save profile & members
    Facebook *facebook = [Facebook sharedInstance];
    [facebook saveProfile:profile forEntityID:ID];
    [facebook saveMembers:_selectedList withGroupID:ID];
    
    // TODO: save current user as founder & owner of the group
    // ...
    
    return YES;
}

- (IBAction)addParticipants:(id)sender {
    
    NSString *groupName = _nameTextField.text;
    NSString *groupSeed = _seedTextField.text;
    // check group name
    if (groupName.length == 0) {
        [self showMessage:@"Group name cannot be empty" withTitle:@"Input Error"];
        [_nameTextField becomeFirstResponder];
        return ;
    }
    // check group seed
    if (groupSeed.length == 0) {
        [self showMessage:@"Seed cannot be empty" withTitle:@"Input Error"];
        [_seedTextField becomeFirstResponder];
        return ;
    } else if (!check_username(groupSeed)) {
        NSString *msg = @"Seed must be composed by characters: 'A'-'Z', 'a'-'z', '0'-'9', '-', '_', '.'";
        [self showMessage:msg withTitle:@"Input Error"];
        [_seedTextField becomeFirstResponder];
        return ;
    }
    
    NSLog(@"selected: %@", _selectedList);
    if (_selectedList.count == 0) {
        [self showMessage:@"Please select at least ONE contact" withTitle:@"Group Chat"];
        return ;
    }
    
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:_selectedList.count];
    DIMID *ID;
    DIMAccount *contact;
    NSString *name;
    for (ID in _selectedList) {
        contact = MKMAccountWithID(ID);
        name = account_title(contact);
        [mArray addObject:name];
    }
    NSString *message = [mArray componentsJoinedByString:@"\n"];
    
    NSString *title = [NSString stringWithFormat:@"Group: %@", groupName];
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        if ([self submitGroupInfo]) {
            // notice
            const NSString *name = kNotificationName_GroupMembersUpdated;
            NSDictionary *info = @{@"group":self->_group};
            [NSNotificationCenter postNotificationName:name
                                                object:self
                                              userInfo:info];
            // dismiss this view controller
            [self dismissViewControllerAnimated:YES completion:^{
                //
            }];
            // TODO: open chat box
        }
    };
    
    [self showMessage:message
            withTitle:title
        cancelHandler:nil
          cacelButton:@"Cancel"
       defaultHandler:handler
        defaultButton:@"Submit"];
}

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC {
    [super unwindForSegue:unwindSegue towardsViewController:subsequentVC];
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        // founder
        return @"Owner";
    } else if (section == 1) {
        // members
        return @"Members";
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    
    if (section == 0) {
        // founder
        return nil;
    } else if (section == 1) {
        // members
        return indexPath;
    }
    return [super tableView:tableView willSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        // founder
    } else if (section == 1) {
        // candidates
        const DIMID *ID = [_candidateList objectAtIndex:row];
        NSAssert(![_selectedList containsObject:ID], @"%@ should not in selected list: %@", ID, _selectedList);
        [_selectedList addObject:ID];
        NSLog(@"select: %@", ID);
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        // founder
    } else if (section == 1) {
        // candidates
        const DIMID *ID = [_candidateList objectAtIndex:row];
        NSAssert([_selectedList containsObject:ID], @"contact not selected: %@", ID);
        [_selectedList removeObject:ID];
        NSLog(@"deselect: %@", ID);
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // founder
        if (_founder) {
            return 1;
        } else {
            return 0;
        }
    } else if (section == 1) {
        // candidates
        return _candidateList.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ParticipantManageCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"participantCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        // founder
        cell.participant = _founder;
        cell.userInteractionEnabled = NO;
    } else if (section == 1) {
        // candidates
        Client *client = [Client sharedInstance];
        DIMUser *user = client.currentUser;
        const DIMID *contact;
        contact = [_candidateList objectAtIndex:row];
        cell.participant = contact;
        
        if ([contact isEqual:_founder] ||
            [contact isEqual:user.ID]) {
            // fixed
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.userInteractionEnabled = NO;
        } else if ([_selectedList containsObject:contact]) {
            // selected
            cell.userInteractionEnabled = YES;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            // others
            cell.userInteractionEnabled = YES;
            cell.accessoryType = UITableViewCellAccessoryNone;
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
