//
//  ConversationsTableViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "Facebook.h"
#import "MessageProcessor.h"

#import "ChatViewController.h"

#import "ConversationsTableViewController.h"

@interface ConversationsTableViewController ()

@end

@implementation ConversationsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(reloadData)
               name:@"MessageUpdate"
             object:nil];
}

- (void)reloadData {
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    [msgDB reloadData];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    return [msgDB numberOfConversations];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // fix a bug with UISearchBar
    tableView = self.tableView;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConversationCell" forIndexPath:indexPath];
    
    //NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    // Configure the cell...
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    DIMConversation *chat = [msgDB conversationAtIndex:row];
    
    DIMEntity *entity;
    if (MKMNetwork_IsPerson(chat.ID.type)) {
        entity = MKMContactWithID(chat.ID);
    } else if (MKMNetwork_IsGroup(chat.ID.type)) {
        entity = MKMGroupWithID(chat.ID);
    }
    
    cell.textLabel.text = entity.name;
    cell.detailTextLabel.text = chat.ID;
    
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
    
    if ([segue.identifier isEqualToString:@"startChat"]) {
        UITableViewCell *cell = sender;
        DIMID *ID = [DIMID IDWithID:cell.detailTextLabel.text];
        DIMConversation *convers = DIMConversationWithID(ID);
        
        ChatViewController *chatVC = segue.destinationViewController;
        if (![chatVC isKindOfClass:[ChatViewController class]]) {
            chatVC = (ChatViewController *)[(UINavigationController *)chatVC visibleViewController];
        }
        chatVC.conversation = convers;
    }
}

@end
