//
//  ParticipantsManageTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"

#import "ParticipantManageCell.h"
#import "Client.h"

#import "ParticipantsManageTableViewController.h"

@interface ParticipantsManageTableViewController () {
    
    NSMutableArray *_contactsList;
    NSMutableArray *_selectedList;
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
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    NSInteger count = [barrack numberOfContactsInUser:user];
    DIMID *contact;
    
    _contactsList = [[NSMutableArray alloc] initWithCapacity:count];

    if (MKMNetwork_IsCommunicator(_conversation.ID.type)) {
        for (NSInteger index = 0; index < count; ++index) {
            contact = [barrack user:user contactAtIndex:index];
            if (!contact.isValid) {
                NSAssert(false, @"contact error at index: %ld", index);
                continue;
            }
            if ([contact isEqual:user.ID]) {
                NSLog(@"ignore current user: %@", contact);
                continue;
            }
            if ([contact isEqual:_conversation.ID]) {
                NSLog(@"ignore current contact: %@", contact);
                continue;
            }
            [_contactsList addObject:contact];
        }
    } else if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        DIMGroup *group = MKMGroupWithID(_conversation.ID);
        for (NSInteger index = 0; index < count; ++index) {
            contact = [barrack user:user contactAtIndex:index];
            if (!contact.isValid) {
                NSAssert(false, @"contact error at index: %ld", index);
                continue;
            }
            if ([contact isEqual:user.ID]) {
                NSLog(@"ignore current user: %@", contact);
                continue;
            }
            if ([group isMember:contact]) {
                NSLog(@"ignore exists member: %@", contact);
                continue;
            }
            [_contactsList addObject:contact];
        }
    }

    
    _selectedList = [[NSMutableArray alloc] init];
}

- (IBAction)addParticipants:(id)sender {
    NSLog(@"addParticipants: %@", _selectedList);
}

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC {
    [super unwindForSegue:unwindSegue towardsViewController:subsequentVC];
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    DIMID *ID = [_contactsList objectAtIndex:row];
    NSAssert(![_selectedList containsObject:ID], @"error");
    [_selectedList addObject:ID];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    DIMID *ID = [_contactsList objectAtIndex:row];
    NSAssert([_selectedList containsObject:ID], @"error");
    [_selectedList removeObject:ID];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _contactsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ParticipantManageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"participantManageCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSInteger row = indexPath.row;
    cell.participant = [_contactsList objectAtIndex:row];
    
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
