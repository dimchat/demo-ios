//
//  ConversationsTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Extension.h"
#import "User.h"
#import "MessageDatabase.h"
#import "Client.h"
#import "DIMClientConstants.h"
#import "ChatViewController.h"
#import "ConversationCell.h"
#import "ConversationsTableViewController.h"

@interface ConversationsTableViewController ()<UITableViewDelegate, UITableViewDataSource>

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

- (void)dealloc{

    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addDataObserver];
}

-(void)addDataObserver{
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(loadData)
               name:DIMConversationUpdatedNotification object:nil];
    [nc addObserver:self selector:@selector(onServerStateChanged:)
               name:kNotificationName_ServerStateChanged object:nil];
    
    [nc addObserver:self selector:@selector(onGroupMembersUpdated:)
               name:kNotificationName_GroupMembersUpdated object:nil];
}

- (void)loadData {
    [NSObject performBlockOnMainThread:^{
        [self.tableView reloadData];
    } waitUntilDone:NO];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
}

- (void)onGroupMembersUpdated:(NSNotification *)notification {
    NSString *name = notification.name;
//    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_GroupMembersUpdated]) {
        // TODO: open chat box for new group
//        DIMID groupID = [info objectForKey:@"group"];
//        DIMConversation *chatBox = DIMConversationWithID(groupID);
//        //[self performSegueWithIdentifier:@"startChat" sender:chatBox];
    }
}

- (void)onServerStateChanged:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    if ([name isEqual:kNotificationName_ServerStateChanged]) {
        NSString *title;
        NSString *state = [info objectForKey:@"state"];
        if ([state isEqualToString:kDIMServerState_Default]) {
            title = NSLocalizedString(@"Disconnected!", nil);
        } else if ([state isEqualToString:kDIMServerState_Connecting]) {
            title = NSLocalizedString(@"Connecting ...", nil);
        } else if ([state isEqualToString:kDIMServerState_Connected]) {
            title = NSLocalizedString(@"Connected!", nil);
        } else if ([state isEqualToString:kDIMServerState_Handshaking]) {
            title = NSLocalizedString(@"Authenticating ...", nil);
        } else if ([state isEqualToString:kDIMServerState_Running]) {
            title = NSLocalizedString(@"Chats", @"title");
        } else if ([state isEqualToString:kDIMServerState_Error]) {
            title = NSLocalizedString(@"Network error!", nil);
        } else if ([state isEqualToString:kDIMServerState_Stopped]) {
            title = NSLocalizedString(@"Connection stopped!", nil);
        } else {
            NSAssert(false, @"unexpected state: %@", state);
        }
        [NSObject performBlockOnMainThread:^{
            self.navigationItem.title = title;
        } waitUntilDone:NO];
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
    MessageDatabase *msgDB = [MessageDatabase sharedInstance];
    return [msgDB numberOfConversations];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConversationCell" forIndexPath:indexPath];
    NSInteger row = indexPath.row;
    
    MessageDatabase *msgDB = [MessageDatabase sharedInstance];
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    DIMConversation *chat = [clerk conversationWithID:[msgDB conversationAtIndex:row]];
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
        
        MessageDatabase *msgDB = [MessageDatabase sharedInstance];
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
    
    MessageDatabase *msgDB = [MessageDatabase sharedInstance];
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    DIMConversation *convers = [clerk conversationWithID:[msgDB conversationAtIndex:indexPath.row]];
    
    ChatViewController *vc = [[ChatViewController alloc] init];
    vc.conversation = convers;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
