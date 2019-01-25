//
//  ChatViewController.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MessageProcessor.h"

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
    NSLog(@"title: %@", _conversation.title);
    
    _tableFrame = _messagesTableView.frame;
    _trayFrame = _trayView.frame;
    
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(keyboardWillShow:)
               name:UIKeyboardWillShowNotification
             object:nil];
    
    [dc addObserver:self
           selector:@selector(keyboardWillHide:)
               name:UIKeyboardWillHideNotification
             object:nil];
    
    [dc addObserver:self
           selector:@selector(reloadData)
               name:@"MessageUpdate"
             object:nil];
}

- (void)reloadData {
    MessageProcessor *msgDB = [MessageProcessor sharedInstance];
    [msgDB reloadData];
    [self.messagesTableView reloadData];
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

- (IBAction)send:(id)senderObject {
    NSString *text = _inputTextField.text;
    if (text.length == 0) {
        NSLog(@"empty");
        return;
    }
    
    [self _hideKeyboard];

    NSLog(@"send text: %@", text);
    
    DIMUser *user = [DIMClient sharedInstance].currentUser;
    DIMID *sender = user.ID;
    DIMID *receiver = _conversation.ID;
    
    DIMMessageContent *content = [[DIMMessageContent alloc] initWithText:text];
    
    DIMInstantMessage *iMsg = [[DIMInstantMessage alloc] initWithContent:content
                                                                  sender:sender
                                                                receiver:receiver
                                                                    time:nil];
    NSLog(@"iMsg: %@", iMsg);
    
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    [trans sendMessage:iMsg callback:^(const DKDReliableMessage * _Nonnull rMsg, const NSError * _Nullable error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else {
            NSLog(@"message sent: %@ -> %@", iMsg, rMsg);
        }
    }];
    
    [_conversation insertMessage:iMsg];
    
    _inputTextField.text = @"";
    
    [_messagesTableView reloadData];
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
    UITableViewCell *cell;
    
    // Configure the cell...
    //    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    
    DIMInstantMessage *iMsg = [_conversation messageAtIndex:row];
    DIMEnvelope *env = iMsg.envelope;
    DIMMessageContent *content = iMsg.content;
    
    if ([env.sender isEqual:user.ID]) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MyMsgCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MsgCell" forIndexPath:indexPath];
    }
    
    NSDate *time = env.time;
    
    NSString *detail = [NSString stringWithFormat:@"%@ [%@]", iMsg.envelope.sender.name, NSStringFromDate(time)];
    
    cell.textLabel.text = content.text;
    cell.detailTextLabel.text = detail;
    
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
