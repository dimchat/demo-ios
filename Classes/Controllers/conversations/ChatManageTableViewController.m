//
//  ChatManageTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "ParticipantsCollectionViewController.h"

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
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Conversations" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"participantsCollectionViewController"];
    ParticipantsCollectionViewController *participantsCVC;
    participantsCVC = (ParticipantsCollectionViewController *)vc;
    participantsCVC.conversation = _conversation;
    _participantsCollectionViewController = participantsCVC;
}

//- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(id<UIContentContainer>)container {
//    [_participantsCollectionViewController.collectionView reloadData];
//    [super systemLayoutFittingSizeDidChangeForChildContentContainer:container];
//}

#pragma mark - Table view delegate

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
        if (row == 0) {
            // Name
            key = @"Name";
            DIMProfile *profile = MKMProfileForID(_conversation.ID);
            value = profile.name;
            if (!value) {
                value = _conversation.ID.name;
            }
            cell.textLabel.text = key;
            cell.detailTextLabel.text = value;
        } else if (row == 1) {
            // QR Code
        }
    } else if (section == 2) {
        // functions
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
