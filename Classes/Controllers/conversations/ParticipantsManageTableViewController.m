//
//  ParticipantsManageTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "UIImageView+Extension.h"
#import "UIViewController+Extension.h"
#import "DIMProfile+Extension.h"
#import "Facebook+Profile.h"
#import "Facebook+Register.h"
#import "Client.h"
#import "MessageDatabase.h"
#import "ParticipantManageCell.h"
#import "ParticipantsManageTableViewController.h"

/**
 *  Check Username Valid
 *
 * @param username - format: ^[A-Za-z0-9_-\.]+$
 * @return YES on valid
 */
static inline BOOL check_username(NSString *username) {
    NSString *pattern = @"^[A-Za-z0-9._-]+$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [pred evaluateWithObject:username];
}

@interface ParticipantsManageTableViewController () {
    
    DIMGroup *_group;
    DIMID _founder;
    NSArray<DIMID> *_memberList;
    
    NSArray<DIMID> *_candidateList;
    NSMutableArray<DIMID> *_selectedList;
}

@end

@implementation ParticipantsManageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_logoImageView roundedCorner];
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    // 1. group info
    if (MKMIDIsGroup(_conversation.ID)) {
        // exists group
        _group = DIMGroupWithID(_conversation.ID);
        _founder = _group.founder;
        // Notice: the group member list will/will not include the founder
        _memberList = _group.members;
        
        // 1.1. logo
        NSString *name = _group.name;
        MKMBulletin *profile = [_group documentWithType:MKMDocument_Bulletin];
        UIImage *logoImage = [profile logoImageWithSize:_logoImageView.bounds.size];
        if (logoImage) {
            [_logoImageView setImage:logoImage];
        } else {
            if (name.length > 0) {
                [_logoImageView setText:[name substringToIndex:1]];
            } else {
                [_logoImageView setText:@"[Đ]"];
            }
        }
        
        // 1.2. name
        _nameTextField.text = name;
        if (![_group isOwner:user.ID]) {
            _nameTextField.enabled = NO;
        }
        
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
        _seedTextField.text = [NSString stringWithFormat:@"Group-%u", seed];
        _seedTextField.enabled = YES;
    }
    
    // 2. candidates
    _candidateList = [self groupMemberCandidates:_group currentUser:user];
    
    // 3. selected list
    _selectedList = [[NSMutableArray alloc] init];
    [_selectedList addObject:user.ID];
    if (_founder && ![_founder isEqual:user.ID]) {
        [_selectedList addObject:_founder];
    }
    if (!_group && MKMIDIsUser(_conversation.ID)) {
        if (![_selectedList containsObject:_conversation.ID]) {
            [_selectedList addObject:_conversation.ID];
        }
    }
    if (_memberList.count > 0) {
        for (DIMID item in _memberList) {
            if ([_selectedList containsObject:item]) {
                continue;
            }
            [_selectedList addObject:item];
        }
    }
}

-(NSArray <DIMID> *)groupMemberCandidates:(DIMGroup *)group currentUser:(DIMUser *)user {
    DIMID founder = group.founder;
    NSArray<DIMID> *members = group.members;
    DIMID current = user.ID;
    NSArray<DIMID> *contacts = user.contacts;
    
    NSMutableArray *filterContacts = [[NSMutableArray alloc] init];
    //Filter Group IDs
    for (DIMID contactID in contacts) {
        
        if (!MKMIDIsGroup(contactID)) {
            [filterContacts addObject:contactID];
        }
    }
    
    DIMID ID;
    NSMutableArray *candidates = [[NSMutableArray alloc] initWithCapacity:(members.count + filterContacts.count)];
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
    for (ID in filterContacts) {
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
    DIMUser *user = client.currentUser;
    id<DIMUserDataSource> dataSource = user.dataSource;
    DIMSignKey signKey = [dataSource privateKeyForVisaSignature:user.ID];
    
    DIMID ID = _conversation.ID;
    NSString *seed = _seedTextField.text;
    NSString *name = _nameTextField.text;
    DIMDocument profile;
//    NSMutableArray<DIMID> *members;
    
    if (MKMIDIsGroup(ID)) {
        // exists group
        _group = DIMGroupWithID(ID);
        profile = _group.bulletin;
        if (!profile) {
            profile = MKMDocumentNew(MKMDocument_Bulletin, ID);
        }
        [profile setName:name];
        [profile sign:signKey];
        BOOL success = [client updateGroupWithID:ID
                                         members:_selectedList
                                         profile:profile];
        if (!success) {
            NSLog(@"failed to update group: %@, %@, %@", ID, _selectedList, profile);
            [self showMessage:[NSString stringWithFormat:@"%@\n%@", name, ID.name] withTitle:NSLocalizedString(@"Update Group Failed!", nil)];
            return NO;
        }
        NSLog(@"update group: %@, profile: %@, members: %@", ID, profile, _selectedList);
    } else {
        // new group
        _group = [client createGroupWithSeed:seed
                                        name:name
                                     members:_selectedList];
        if (!_group) {
            NSLog(@"failed to create group: %@, %@, %@", seed, _selectedList, name);
            [self showMessage:[NSString stringWithFormat:@"%@\n%@", name, seed] withTitle:NSLocalizedString(@"Create Group Failed!", nil)];
            return NO;
        }
        ID = _group.ID;
        profile = MKMDocumentNew(MKMDocument_Bulletin, ID);
        [profile setName:name];
        [profile sign:signKey];
        NSLog(@"new group: %@, profile: %@, members: %@", ID, profile, _selectedList);
    }
    
    // save profile & members
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    [facebook saveDocument:profile];
    [facebook saveMembers:_selectedList group:_group.ID];
    return YES;
}

- (IBAction)addParticipants:(id)sender {
    
    NSString *groupName = _nameTextField.text;
    NSString *groupSeed = _seedTextField.text;
    // check group name
    if (groupName.length == 0) {
        [self showMessage:NSLocalizedString(@"Group name cannot be empty.", nil)
                withTitle:NSLocalizedString(@"Input Error!", nil)];
        [_nameTextField becomeFirstResponder];
        return ;
    }
    // check group seed
    if (groupSeed.length == 0) {
        [self showMessage:NSLocalizedString(@"Seed cannot be empty.", nil)
                withTitle:NSLocalizedString(@"Input Error!", nil)];
        [_seedTextField becomeFirstResponder];
        return ;
    } else if (!check_username(groupSeed)) {
        NSString *msg = NSLocalizedString(@"Seed must be composed of letters, digits, underscores, or hyphens.", nil);
        [self showMessage:msg
                withTitle:NSLocalizedString(@"Input Error!", nil)];
        [_seedTextField becomeFirstResponder];
        return ;
    }
    
    NSLog(@"selected: %@", _selectedList);
    if (_selectedList.count == 0) {
        [self showMessage:NSLocalizedString(@"Please select at least ONE contact.", nil)
                withTitle:NSLocalizedString(@"Group Member Error!", nil)];
        return ;
    }
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:_selectedList.count];
    DIMID ID;
    NSString *name;
    NSArray *list = [_selectedList copy];
    for (ID in list) {
        name = [facebook name:ID];
        [mArray addObject:name];
    }
    NSString *message = [mArray componentsJoinedByString:@"\n"];
    
    NSString *title = [NSString stringWithFormat:@"Group: %@", groupName];
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        if ([self submitGroupInfo]) {
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
         cancelButton:NSLocalizedString(@"Cancel", nil)
       defaultHandler:handler
        defaultButton:NSLocalizedString(@"Submit", nil)];
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
        return NSLocalizedString(@"Owner", nil);
    } else if (section == 1) {
        // members
        return NSLocalizedString(@"Members", nil);
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
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        // founder
    } else if (section == 1) {
        // candidates
        DIMID ID = [_candidateList objectAtIndex:row];
        //NSAssert(![_selectedList containsObject:ID], @"%@ should not in selected list: %@", ID, _selectedList);
        
        if([_selectedList containsObject:ID]){
            [_selectedList removeObject:ID];
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryNone;
            
        }else{
            [_selectedList addObject:ID];
            NSLog(@"select: %@", ID);
        
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    NSInteger section = indexPath.section;
//    NSInteger row = indexPath.row;
//
//    if (section == 0) {
//        // founder
//    } else if (section == 1) {
//        // candidates
//        DIMID ID = [_candidateList objectAtIndex:row];
//        [_selectedList removeObject:ID];
//        NSLog(@"deselect: %@", ID);
//
//        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//        cell.accessoryType = UITableViewCellAccessoryNone;
//    }
//}

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
        DIMID contact;
        contact = [_candidateList objectAtIndex:row];
        cell.participant = contact;
        
        if (_group && ![_group isOwner:user.ID] && [_memberList containsObject:contact]) {
            // fixed
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.userInteractionEnabled = NO;
        } else if ([contact isEqual:_founder] || [_group isOwner:contact] || [contact isEqual:user.ID]) {
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

@end
