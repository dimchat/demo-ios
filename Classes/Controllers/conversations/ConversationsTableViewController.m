//
//  ConversationsTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIStoryboard+Extension.h"
#import "UIStoryboardSegue+Extension.h"
#import "User.h"
#import "Facebook.h"
#import "MessageProcessor.h"
#import "Client.h"
#import "ChatViewController.h"
#import "ConversationCell.h"
#import "ConversationsTableViewController.h"

@interface ConversationsTableViewController ()<UITableViewDelegate, UITableViewDataSource> {
    
    NSString *_fixedTitle;
}

@property(nonatomic, strong) UITableView *tableView;

@end

@implementation ConversationsTableViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.title = NSLocalizedString(@"Chats", @"title");
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerClass:[ConversationCell class] forCellReuseIdentifier:@"ConversationCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSNotificationCenter addObserver:self.tableView
                             selector:@selector(reloadData)
                                 name:kNotificationName_MessageUpdated
                               object:nil];
    [NSNotificationCenter addObserver:self.tableView
                             selector:@selector(reloadData)
                                 name:kNotificationName_MessageCleaned
                               object:nil];
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(onServerStateChanged:)
                                 name:kNotificationName_ServerStateChanged
                               object:nil];
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(onGroupMembersUpdated:)
                                 name:kNotificationName_GroupMembersUpdated
                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.prefersLargeTitles = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (void)onGroupMembersUpdated:(NSNotification *)notification {
    NSString *name = notification.name;
//    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_GroupMembersUpdated]) {
        // TODO: open chat box for new group
//        DIMID *groupID = [info objectForKey:@"group"];
//        DIMConversation *chatBox = DIMConversationWithID(groupID);
//        //[self performSegueWithIdentifier:@"startChat" sender:chatBox];
    }
}

- (void)onServerStateChanged:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    if ([name isEqual:kNotificationName_ServerStateChanged]) {
        NSString *state = [info objectForKey:@"state"];
        if ([state isEqualToString:kDIMServerState_Default]) {
            self.navigationItem.title = NSLocalizedString(@"Disconnected!", nil);
        } else if ([state isEqualToString:kDIMServerState_Connecting]) {
            self.navigationItem.title = NSLocalizedString(@"Connecting ...", nil);
        } else if ([state isEqualToString:kDIMServerState_Connected]) {
            self.navigationItem.title = NSLocalizedString(@"Connected!", nil);
        } else if ([state isEqualToString:kDIMServerState_Handshaking]) {
            self.navigationItem.title = NSLocalizedString(@"Authenticating ...", nil);
        } else if ([state isEqualToString:kDIMServerState_Running]) {
            self.navigationItem.title = NSLocalizedString(@"Chats", @"title");
        } else if ([state isEqualToString:kDIMServerState_Error]) {
            self.navigationItem.title = NSLocalizedString(@"Network error!", nil);
        } else if ([state isEqualToString:kDIMServerState_Stopped]) {
            self.navigationItem.title = NSLocalizedString(@"Connection stopped!", nil);
        } else {
            NSAssert(false, @"unexpected state: %@", state);
        }
    }
}

#pragma mark - Table delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    return [msgDB numberOfConversations];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConversationCell" forIndexPath:indexPath];
    NSInteger row = indexPath.row;
    
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    DIMConversation *chat = [msgDB conversationAtIndex:row];
    cell.conversation = chat;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
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
        [msgDB removeConversationAtIndex:row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    
    [tableView endUpdates];
}

#pragma mark - Navigation

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    DIMConversation *convers = [msgDB conversationAtIndex:indexPath.row];
    
    ChatViewController *vc = [[ChatViewController alloc] init];
    vc.conversation = convers;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
