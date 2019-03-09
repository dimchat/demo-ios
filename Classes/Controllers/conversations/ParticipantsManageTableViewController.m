//
//  ParticipantsManageTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"
#import "UIViewController+Extension.h"

#import "User.h"
#import "Facebook+Register.h"
#import "Client.h"

#import "ParticipantManageCell.h"

#import "ParticipantsManageTableViewController.h"

@interface ParticipantsManageTableViewController () {
    
    NSArray<const DIMID *> *_membersList;
    
    NSArray<const DIMID *> *_contactsList;
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
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    // 1. contacts list
    _contactsList = user.contacts;
    _selectedList = [[NSMutableArray alloc] init];
    
    [_logoImageView roundedCorner];
    
    const DIMID *ID = _conversation.ID;
    if (MKMNetwork_IsGroup(ID.type)) {
        DIMGroup *group = MKMGroupWithID(ID);
        DIMProfile *profile = MKMProfileForID(ID);
        
        // 2. members list
        _membersList = group.members;
        
        // 3. selected list
        const DIMID *contact;
        for (contact in _membersList) {
            if ([_contactsList containsObject:contact]) {
                [_selectedList addObject:contact];
            } else {
                //NSAssert(false, @"unexpected member: %@", contact);
            }
        }
        
        // 4. logo
        NSString *name = profile.name;
        if (name.length > 0) {
            [_logoImageView setText:[NSString stringWithFormat:@"[%@]", [name substringToIndex:1]]];
        } else {
            [_logoImageView setText:@"[Đ]"];
        }
        // 5. name
        _nameTextField.text = name;
        // 6. seed
        _seedTextField.text = ID.name;
        _seedTextField.enabled = NO;
    } else {
        // 2. members list
        _membersList = nil;
        
        // 3. selected list
        [_selectedList addObject:_conversation.ID];
        
        // 4. logo
        [_logoImageView setText:@"[Đ]"];
        
        // 5. name
        _nameTextField.text = @"";
        
        // 6. seed
        uint32_t seed = arc4random();
        if (ID.name) {
            _seedTextField.text = [NSString stringWithFormat:@"polylogue-%u-%@", seed, ID.name];
        } else {
            _seedTextField.text = [NSString stringWithFormat:@"polylogue-%u", seed];
        }
        _seedTextField.enabled = YES;
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

- (void)submitGroupInfo {
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
        [client updateGroupWithID:ID
                          members:_selectedList
                          profile:profile];
        NSLog(@"update group: %@, profile: %@", ID, profile);
    } else {
        // new group
        DIMGroup *group = [client createGroupWithSeed:seed
                                              members:_selectedList
                                              profile:@{@"name":name}];
        ID = group.ID;
        profile = [[DIMProfile alloc] initWithDictionary:@{@"ID":ID, @"name":name}];
        NSLog(@"new group: %@, profile: %@", ID, profile);
    }
    
    // save profile & members
    Facebook *facebook = [Facebook sharedInstance];
    [facebook saveProfile:profile forEntityID:ID];
    [facebook saveMembers:_selectedList withGroupID:ID];
    
    // TODO: save current user as founder & owner of the group
    // ...
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
        [self submitGroupInfo];
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
        return @"Members";//[NSString stringWithFormat:@"Members (%lu)", _selectedList.count];
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        const DIMID *ID = [_contactsList objectAtIndex:row];
        NSAssert(![_selectedList containsObject:ID], @"error");
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
        const DIMID *ID = [_contactsList objectAtIndex:row];
        NSAssert([_selectedList containsObject:ID], @"error");
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
        return _contactsList.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ParticipantManageCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"participantCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    const DIMID *contact;
    
    if (section == 0) {
        contact = [_contactsList objectAtIndex:row];
        cell.participant = contact;
        
        if ([_selectedList containsObject:contact]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
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
