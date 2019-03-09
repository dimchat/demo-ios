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
    
    UIButton *_memberColumnButton;
    UIButton *_contactColumnButton;
}

@end

@implementation ParticipantsManageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _selectedList = [[NSMutableArray alloc] init];
    
    [_logoImageView roundedCorner];
    [_logoImageView setText:@"[Đ]"];
    
    const DIMID *ID = _conversation.ID;
    if (MKMNetwork_IsGroup(ID.type)) {
        DIMProfile *profile = MKMProfileForID(ID);
        _nameTextField.text = profile.name;
        _seedTextField.text = ID.name;
        _seedTextField.enabled = NO;
    } else {
        uint32_t seed = arc4random();
        if (ID.name) {
            _seedTextField.text = [NSString stringWithFormat:@"polylogue-%u-%@", seed, ID.name];
        } else {
            _seedTextField.text = [NSString stringWithFormat:@"polylogue-%u", seed];
        }
        _seedTextField.enabled = YES;
    }
    
    // members
    DIMGroup *group = nil;
    if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        group = MKMGroupWithID(_conversation.ID);
        _membersList = group.members;
    } else {
        [_selectedList addObject:_conversation.ID];
        _membersList = nil;
    }
    
    // contacts
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    _contactsList = user.contacts;
    
    // members column
    {
        NSString *normalTitle = [NSString stringWithFormat:@"Members (%lu)", _membersList.count];;
        NSString *selectedTitle = @"Members";
        NSInteger section = 0;
        BOOL selected = NO;
        
        CGRect bounds = self.tableView.bounds;
        CGFloat height = [self tableView:self.tableView heightForHeaderInSection:section];
        CGRect frame = CGRectMake(0, 0, bounds.size.width, height);
        UIButton *button = [[UIButton alloc] initWithFrame:frame];
        [button addTarget:self action:@selector(toggleUserList:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:normalTitle forState:UIControlStateNormal];
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        button.backgroundColor = [UIColor groupTableViewBackgroundColor];
        button.tag = section;
        button.selected = selected;
        
        _memberColumnButton = button;
    }
    // contacts column
    {
        NSString *normalTitle = [NSString stringWithFormat:@"Contacts (%lu)", _contactsList.count];;
        NSString *selectedTitle = @"Contacts";
        NSInteger section = 1;
        BOOL selected = YES;
        
        CGRect bounds = self.tableView.bounds;
        CGFloat height = [self tableView:self.tableView heightForHeaderInSection:section];
        CGRect frame = CGRectMake(0, 0, bounds.size.width, height);
        UIButton *button = [[UIButton alloc] initWithFrame:frame];
        [button addTarget:self action:@selector(toggleUserList:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:normalTitle forState:UIControlStateNormal];
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        button.backgroundColor = [UIColor groupTableViewBackgroundColor];
        button.tag = section;
        button.selected = selected;
        
        _contactColumnButton = button;
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

- (void)addGroupMembers:(NSArray<const DIMID *> *)selectedList {
    const DIMID *ID = _conversation.ID;
    NSString *seed = _seedTextField.text;
    NSString *name = _nameTextField.text;
    DIMProfile *profile;
    NSMutableArray<const DIMID *> *members;
    
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
        NSLog(@"update group: %@, profile: %@", ID, profile);
        
        // update members
        NSUInteger count = _membersList.count + selectedList.count;
        members = [[NSMutableArray alloc] initWithCapacity:count];
        NSString *item;
        for (item in _membersList) {
            [members addObject:[DIMID IDWithID:item]];
        }
        for (item in selectedList) {
            [members addObject:[DIMID IDWithID:item]];
        }
        NSLog(@"update group members: %lu + %lu -> %lu",
              _membersList.count, selectedList.count, members.count);
    } else {
        // new group
        Client *client = [Client sharedInstance];
        DIMGroup *group = [client createGroupWithSeed:seed
                                                 name:name
                                              members:selectedList];
        ID = group.ID;
        profile = [[DIMProfile alloc] initWithDictionary:@{@"ID":ID,
                                                           @"name":name,
                                                           }];
        NSLog(@"new group: %@, profile: %@", ID, profile);
        
        // new members
        NSUInteger count = selectedList.count;
        members = [[NSMutableArray alloc] initWithCapacity:count];
        NSString *item;
        for (item in selectedList) {
            [members addObject:[DIMID IDWithID:item]];
        }
        NSLog(@"new group members: %lu", members.count);
    }
    
    // save profile & members
    Facebook *facebook = [Facebook sharedInstance];
    [facebook saveProfile:profile forEntityID:ID];
    [facebook saveMembers:members withGroupID:ID];
    
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
    
    NSLog(@"addParticipants: %@", _selectedList);
    // TODO: add participants to group chat
    if (_selectedList.count == 0 && _membersList.count == 0) {
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
    
    NSString *title = nil;
    if (_selectedList.count == 1) {
        title = @"Adding Group Member";
    } else {
        title = @"Adding Group Members";
    }
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        NSLog(@"Adding group members: %@", self->_selectedList);
        [self addGroupMembers:self->_selectedList];
    };
    [self showMessage:message
            withTitle:title
        cancelHandler:nil
       defaultHandler:handler];
}

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC {
    [super unwindForSegue:unwindSegue towardsViewController:subsequentVC];
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)toggleUserList:(UIButton *)button {
    button.selected = !button.selected;
    NSLog(@"button: %ld, selected: %d", (long)button.tag, button.selected);
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        // members
        return 32;
    } else if (section == 1) {
        // contacts
        return 32;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        // members
        return _memberColumnButton;
    } else if (section == 1) {
        // contacts
        return _contactColumnButton;
    }
    
    return [super tableView:tableView viewForHeaderInSection:section];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
//}

- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (section == 0) {
        // members
        return nil;
    } else if (section == 1) {
        // contacts
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        // members
    } else if (section == 1) {
        // contacts
        const DIMID *ID = [_contactsList objectAtIndex:row];
        NSAssert(![_selectedList containsObject:ID], @"error");
        [_selectedList addObject:ID];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        // members
    } else if (section == 1) {
        // contacts
        const DIMID *ID = [_contactsList objectAtIndex:row];
        NSAssert([_selectedList containsObject:ID], @"error");
        [_selectedList removeObject:ID];
        
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
        // members
        if (_memberColumnButton.selected) {
            return _membersList.count;
        } else {
            return 0;
        }
    } else if (section == 1) {
        // contacts
        if (_contactColumnButton.selected) {
            return _contactsList.count;
        } else {
            return 0;
        }
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
        // members
        contact = [_membersList objectAtIndex:row];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
    } else if (section == 1) {
        // contacts
        contact = [_contactsList objectAtIndex:row];
        
        if ([contact isEqual:_conversation.ID] ||
            [_membersList containsObject:contact]) {
            // fixed cell
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.userInteractionEnabled = NO;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = YES;
        }
    }
    
    cell.participant = contact;
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
