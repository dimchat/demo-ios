//
//  ChatManageTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIViewController+Extension.h"
#import "UIStoryboard+Extension.h"
#import "UIStoryboardSegue+Extension.h"

#import "MessageProcessor.h"
#import "Client.h"
#import "User.h"

#import "ParticipantsManageTableViewController.h"

#import "ParticipantsCollectionViewController.h"

#import "ReportViewController.h"

#import "ChatManageTableViewController.h"

@interface ChatManageTableViewController ()

@property (strong, nonatomic) ParticipantsCollectionViewController *participantsCollectionViewController;

@end

@implementation ChatManageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSLog(@"manage conversation: %@", _conversation.ID);
    ParticipantsCollectionViewController *vc;
    vc = [UIStoryboard instantiateViewControllerWithIdentifier:@"participantsCollectionViewController" storyboardName:@"Conversations"];
    vc.conversation = _conversation;
    _participantsCollectionViewController = vc;
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(onGroupMembersUpdated:)
                                 name:kNotificationName_GroupMembersUpdated
                               object:nil];
}

- (void)onGroupMembersUpdated:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_GroupMembersUpdated]) {
        DIMID *groupID = [info objectForKey:@"group"];
        if ([groupID isEqual:_conversation.ID]) {
            // the same group
            [_participantsCollectionViewController reloadData];
            [_participantsCollectionViewController.collectionView reloadData];
            [self.tableView reloadData];
        } else {
            // dismiss the personal chat box
            [self dismissViewControllerAnimated:YES completion:^{
                //
            }];
        }
    }
}

//- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container {
//    [_participantsCollectionViewController.collectionView reloadData];
//    [super systemLayoutFittingSizeDidChangeForChildContentContainer:container];
//}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (section == 3) {
        // functions
        if (row == 0) {
            // Clear Chat History
            
            NSString *title = NSLocalizedString(@"Clear Chat History", nil);
            NSString *format = NSLocalizedString(@"Are you sure to clear all messages with %@ ?\nThis operation is unrecoverable!", nil);
            NSString *text = [NSString stringWithFormat:format, _conversation.title];
            
            void (^handler)(UIAlertAction *);
            handler = ^(UIAlertAction *action) {
                MessageProcessor *msgDB = [MessageProcessor sharedInstance];
                [msgDB clearConversation:self->_conversation];
            };
            [self showMessage:text withTitle:title cancelHandler:nil defaultHandler:handler];
        } else if (row == 1) {
            // Delete and Leave
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    //NSInteger row = indexPath.row;
    
    if (section == 0) {
        UICollectionViewController *cvc = _participantsCollectionViewController;
        UICollectionViewLayout *cvl = cvc.collectionViewLayout;
        CGSize size = cvl.collectionViewContentSize;
        return size.height;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;//[tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        // member list
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        UIView *view = _participantsCollectionViewController.view;
        UICollectionView *cView = _participantsCollectionViewController.collectionView;
        if (view.superview == nil) {
            cView.frame = cell.bounds;
            [cell addSubview:view];
        }
    } else if (section == 1) {
        // profile
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        NSString *key = nil;
        NSString *value = nil;
        switch (row) {
            case 0: { // Name
                if (MKMNetwork_IsGroup(_conversation.ID.type)) {
                    key = NSLocalizedString(@"Group name", nil);
                } else {
                    key = NSLocalizedString(@"Nickname", nil);
                }
                DIMProfile *profile = DIMProfileForID(_conversation.ID);
                value = profile.name;
                if (!value) {
                    value = _conversation.ID.name;
                }
            }
                break;
                
            case 1: { // seed
                if (MKMNetwork_IsGroup(_conversation.ID.type)) {
                    key = NSLocalizedString(@"Seed", nil);
                } else {
                    key = NSLocalizedString(@"Username", nil);
                }
                value = _conversation.ID.name;
            }
                break;
                
            case 2: { // address
                key = NSLocalizedString(@"Address", nil);
                value = (NSString *)_conversation.ID.address;
            }
                break;
                
            case 3: { // search number
                key = NSLocalizedString(@"Search No.", nil);
                value = search_number(_conversation.ID.number);
            }
                break;
                
            default:
                break;
        }
        cell.textLabel.text = key;
        cell.detailTextLabel.text = value;
    } else if (section == 2) {
        // functions
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        // others
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
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
    NSLog(@"segue: %@", segue);
    
    if ([segue.identifier isEqualToString:@"reportSegue"]) {
        
        ReportViewController *vc = (id)[segue visibleDestinationViewController];
        vc.ID = _conversation.ID;

    }
}

@end
