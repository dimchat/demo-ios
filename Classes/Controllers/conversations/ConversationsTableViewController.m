//
//  ConversationsTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "UIStoryboardSegue+Extension.h"

#import "User.h"
#import "Facebook.h"
#import "MessageProcessor.h"
#import "Client.h"

#import "ChatViewController.h"

#import "ConversationCell.h"

#import "ConversationsTableViewController.h"

@interface ConversationsTableViewController () {
    
    NSString *_fixedTitle;
}

@end

@implementation ConversationsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    while (_fixedTitle.length == 0) {
        _fixedTitle = self.navigationItem.title;
        if (_fixedTitle.length > 0) {
            break;
        }
        _fixedTitle = self.title;
        if (_fixedTitle.length > 0) {
            break;
        }
        _fixedTitle = @"Secure Chat";
        break;
    }
    
    Client *client = [Client sharedInstance];
    [client addObserver:self
               selector:@selector(reloadData)
                   name:kNotificationName_MessageUpdated
                 object:nil];
    
    [client addObserver:self
               selector:@selector(onServerStateChanged:)
                   name:kNotificationName_ServerStateChanged
                 object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    if (!user) {
        NSLog(@"show accountNavigationController");
        UIViewController *vc = self.parentViewController;
        while (vc && ![vc isKindOfClass:[UITabBarController class]]) {
            vc = vc.parentViewController;
        }
        UITabBarController *tbc = (UITabBarController *)vc;
        tbc.selectedIndex = 2;
    }
}

- (void)onServerStateChanged:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    if ([name isEqualToString:kNotificationName_ServerStateChanged]) {
        NSString *state = [info objectForKey:@"state"];
        if ([state isEqualToString:kDIMServerState_Default]) {
            self.title = @"Disconnected";
        } else if ([state isEqualToString:kDIMServerState_Connecting]) {
            self.title = @"Connecting ...";
        } else if ([state isEqualToString:kDIMServerState_Connected]) {
            self.title = @"Connected";
        } else if ([state isEqualToString:kDIMServerState_Handshaking]) {
            self.title = @"Authenticating ...";
        } else if ([state isEqualToString:kDIMServerState_Running]) {
            self.title = _fixedTitle;
        } else if ([state isEqualToString:kDIMServerState_Error]) {
            self.title = @"Network error!";
        } else if ([state isEqualToString:kDIMServerState_Stopped]) {
            self.title = @"Connection stopped";
        } else {
            NSAssert(false, @"unexpected state: %@", state);
        }
    }
}

- (void)reloadData {
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    [msgDB reloadData];
    [self.tableView reloadData];
}

#pragma mark - Table delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
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
    
    ConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"conversationCell" forIndexPath:indexPath];
    
    //NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    // Configure the cell...
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    DIMConversation *chat = [msgDB conversationAtIndex:row];
    
    NSString *title = nil;
    
    DIMEntity *entity;
    if (MKMNetwork_IsPerson(chat.ID.type)) {
        entity = MKMAccountWithID(chat.ID);
        title = account_title((DIMAccount *)entity);
    } else if (MKMNetwork_IsGroup(chat.ID.type)) {
        entity = MKMGroupWithID(chat.ID);
        title = group_title((DIMGroup *)entity);
    } else {
        title = entity.name;
    }
    cell.conversation = chat;
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView beginUpdates];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        //NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        
        MessageProcessor *msgDB = [MessageProcessor sharedInstance];
        [msgDB clearConversationAtIndex:row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    
    [tableView endUpdates];
}

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
        ConversationCell *cell = sender;
        DIMID *ID = cell.conversation.ID;
        DIMConversation *convers = DIMConversationWithID(ID);
        
        ChatViewController *vc = (id)[segue visibleDestinationViewController];
        vc.conversation = convers;
    }
}

@end
