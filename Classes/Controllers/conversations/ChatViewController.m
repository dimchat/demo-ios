//
//  ChatViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSString+Extension.h"
#import "NSNotificationCenter+Extension.h"

#import "UIStoryboardSegue+Extension.h"

#import "MessageProcessor.h"
#import "Client.h"

#import "MsgCell.h"

#import "ChatManageTableViewController.h"

#import "ChatViewController.h"

@interface ChatViewController () {
    
    CGRect _tableFrame;
    CGRect _trayFrame;
}

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = _conversation.title;
    NSLog(@"title: %@", self.title);
    
    _tableFrame = _messagesTableView.frame;
    _trayFrame = _trayView.frame;
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(onMessageSent:)
                                 name:kNotificationName_MessageSent
                               object:nil];
    [NSNotificationCenter addObserver:self
                             selector:@selector(onSendMessageFailed:)
                                 name:kNotificationName_SendMessageFailed
                               object:nil];;
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(keyboardWillShow:)
                                 name:UIKeyboardWillShowNotification
                               object:nil];
    [NSNotificationCenter addObserver:self
                             selector:@selector(keyboardWillHide:)
                                 name:UIKeyboardWillHideNotification
                               object:nil];
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(reloadData)
                                 name:kNotificationName_MessageUpdated
                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self scrollToBottom];
}

- (void)reloadData {
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    [msgDB reloadData];
    [self.messagesTableView reloadData];
}

- (void)scrollToBottom {
    NSInteger row = [_conversation numberOfMessage];
    if (row > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(row - 1) inSection:0];
        [self.messagesTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGRect tableRect = _tableFrame;
    tableRect.size.height -= keyboardSize.height;
    
    CGRect trayRect = _trayFrame;
    trayRect.origin.y -= keyboardSize.height;
    
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self->_messagesTableView.frame = tableRect;
        self->_trayView.frame = trayRect;
    }];
    
    // scroll to bottom
    [self scrollToBottom];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self->_messagesTableView.frame = self->_tableFrame;
        self->_trayView.frame = self->_trayFrame;
    }];
}

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC {
    [super unwindForSegue:unwindSegue towardsViewController:subsequentVC];
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)_hideKeyboard {
    [self.view endEditing:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [self _hideKeyboard];
}

- (IBAction)beginEditing:(id)sender {
    [self scrollToBottom];
}

- (IBAction)send:(id)senderObject {
    NSString *text = _inputTextField.text;
    if (text.length == 0) {
        NSLog(@"empty");
        return;
    }
    
    [self _hideKeyboard];

    NSLog(@"send text: %@", text);
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    // create message content
    DIMMessageContent *content;
    content = [[DIMMessageContent alloc] initWithText:text];
    
    if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        content.group = _conversation.ID;
    }
    
    // pack message
    DIMInstantMessage *iMsg;
    iMsg = [[DIMInstantMessage alloc] initWithContent:content
                                               sender:user.ID
                                             receiver:_conversation.ID
                                                 time:nil];
    // send out
    [client sendMessage:iMsg];
    
    if (MKMNetwork_IsCommunicator(_conversation.ID.type)) {
        [_conversation insertMessage:iMsg];
    }
    
    _inputTextField.text = @"";
    
    [_messagesTableView reloadData];
}

- (void)onMessageSent:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    DIMInstantMessage *msg = [info objectForKey:@"message"];
    msg = [DIMInstantMessage messageWithMessage:msg];
    NSLog(@"%@: %@", name, msg);
    // TODO: mark the message sent
}

- (void)onSendMessageFailed:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    DIMInstantMessage *msg = [info objectForKey:@"message"];
    msg = [DIMInstantMessage messageWithMessage:msg];
    NSError *error = [info objectForKey:@"error"];
    NSLog(@"%@: %@, error: %@", name, msg, error);
    // TODO: mark the message failed for trying again
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //#warning Incomplete implementation, return the number of sections
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //#warning Incomplete implementation, return the number of rows
    
    return [_conversation numberOfMessage];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell...
    //    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    DIMInstantMessage *iMsg = [_conversation messageAtIndex:row];
    DIMEnvelope *env = iMsg.envelope;
    const DIMID *sender = [DIMID IDWithID:env.sender];
    
    NSString *identifier = @"receivedMsgCell";
    if ([sender isEqual:_conversation.ID]) {
        // message from conversation target
    } else if ([sender isEqual:user.ID]) {
        // message from current user
        identifier = @"sentMsgCell";
    } else {
        NSArray *users = client.users;
        for (user in users) {
            if ([user.ID isEqual:sender]) {
                // message from my account
                identifier = @"sentMsgCell";
            }
        }
    }
    MsgCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.msg = iMsg;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    DIMInstantMessage *iMsg = [_conversation messageAtIndex:row];
    CGRect bounds = tableView.bounds;
    CGSize size = [MsgCell sizeWithMessage:iMsg bounds:bounds];
    return size.height;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"chatDetailSegue"]) {
        
        ChatManageTableViewController *vc = (id)[segue visibleDestinationViewController];
        vc.conversation = _conversation;
    }
}

@end
