//
//  ChatViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSData+Crypto.h"

#import "NSString+Extension.h"
#import "NSNotificationCenter+Extension.h"

#import "UIStoryboardSegue+Extension.h"
#import "UIButton+Extension.h"
#import "UIImage+Extension.h"
#import "UIViewController+Extension.h"

#import "WebViewController.h"
#import "ImagePickerController.h"

#import "MessageProcessor+GroupCommand.h"
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
    
    // TODO: if group members info not found, disable sending and
    //       managing functions (disable the 'chatDetailSegue')
    
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
                             selector:@selector(onMessageUpdated:)
                                 name:kNotificationName_MessageUpdated
                               object:nil];
    [NSNotificationCenter addObserver:self
                             selector:@selector(onMessageCleaned:)
                                 name:kNotificationName_MessageCleaned
                               object:nil];
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(onGroupMembersUpdated:)
                                 name:kNotificationName_GroupMembersUpdated
                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self scrollToBottom];
}

- (void)onMessageUpdated:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_MessageUpdated]) {
        DIMID *ID = [info objectForKey:@"ID"];
        ID = [DIMID IDWithID:ID];
        if ([_conversation.ID isEqual:ID]) {
            [self reloadData];
        }
    }
}

- (void)onMessageCleaned:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_MessageCleaned]) {
        DIMID *ID = [info objectForKey:@"ID"];
        ID = [DIMID IDWithID:ID];
        if ([_conversation.ID isEqual:ID]) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)onGroupMembersUpdated:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_GroupMembersUpdated]) {
        DIMID *groupID = [info objectForKey:@"group"];
        if ([groupID isEqual:_conversation.ID]) {
            // the same group, refresh title
            self.title = _conversation.title;
            NSLog(@"new title: %@", self.title);
        } else {
            // dismiss the personal chat box
            [self dismissViewControllerAnimated:YES completion:^{
                //
            }];
        }
    }
}

- (void)reloadData {
    [self.messagesTableView reloadData];
    [self scrollToBottom];
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

- (IBAction)send:(id)sender {
    NSString *text = _inputTextField.text;
    if (text.length == 0) {
        NSLog(@"empty");
        return;
    }
    
    [self _hideKeyboard];

    DIMConversation *chatBox = _conversation;
    const DIMID *receiver = chatBox.ID;
    NSLog(@"send text: %@ -> %@", text, receiver);
    
    // create message content
    DIMMessageContent *content;
    content = [[DIMMessageContent alloc] initWithText:text];
    
    if (MKMNetwork_IsGroup(receiver.type)) {
        content.group = receiver;
    }
    
    // pack message and send out
    Client *client = [Client sharedInstance];
    DIMInstantMessage *iMsg = [client sendContent:content to:receiver];
    if (!iMsg) {
        NSLog(@"send content failed: %@ -> %@", content, receiver);
        NSString *message = NSLocalizedString(@"Failed to send this message.", nil);
        NSString *title = NSLocalizedString(@"Error!", nil);
        [self showMessage:message withTitle:title];
        return ;
    }
    
    if (MKMNetwork_IsCommunicator(receiver.type)) {
        [chatBox insertMessage:iMsg];
    }
    
    _inputTextField.text = @"";
    
    [self reloadData];
}

- (void)_showImagePickerController:(ImagePickerController *)ipc {
    DIMConversation *chatBox = _conversation;
    const DIMID *receiver = chatBox.ID;
    
    // completion handler
    ImagePickerControllerCompletionHandler handler;
    handler = ^(UIImage * _Nullable image,
                NSString *path,
                NSDictionary<UIImagePickerControllerInfoKey,id> *info,
                UIImagePickerController *ipc) {
        
        NSLog(@"pick image: %@, path: %@", image, path);
        
        // 1. build message content
        DIMMessageContent *content = nil;
        if (image) {
            DIMFileServer *ftp = [DIMFileServer sharedInstance];
            
            CGSize maxSize = CGSizeMake(1024, 1024);
            CGSize imgSize = image.size;
            if (imgSize.width > maxSize.width || imgSize.height > maxSize.height) {
                NSLog(@"original data length: %lu", [image pngData].length);
                image = [image aspectFit:maxSize];
            }
            
            // image file
            NSData *data = [image jpegDataWithQuality:UIImage_JPEGCompressionQuality_Photo];
            NSString *filename = [[[data md5] hexEncode] stringByAppendingPathExtension:@"jpeg"];
            [ftp saveData:data filename:filename];
            
            // thumbnail
            UIImage *thumbnail = [image thumbnail];
            NSData *small = [thumbnail jpegDataWithQuality:UIImage_JPEGCompressionQuality_Thumbnail];
            NSLog(@"thumbnail data length: %lu < %lu, %lu", small.length, data.length, [image pngData].length);
            [ftp saveThumbnail:small filename:filename];
            
            // add image data length & thumbnail into message content
            content = [[DIMMessageContent alloc] initWithImageData:data filename:filename];
            [content setObject:@(data.length) forKey:@"length"];
            [content setObject:[small base64Encode] forKey:@"thumbnail"];
        } else {
            // movie message
            NSData *data = [NSData dataWithContentsOfFile:path];
            content = [[DIMMessageContent alloc] initWithVideoData:data filename:@"video.mp4"];
            // TODO: snapshot
        }
        
        if (MKMNetwork_IsGroup(receiver.type)) {
            content.group = receiver;
        }
        
        // 2. pack message and send out
        Client *client = [Client sharedInstance];
        DIMInstantMessage *iMsg = [client sendContent:content to:receiver];
        if (!iMsg) {
            NSLog(@"send content failed: %@ -> %@", content, receiver);
            NSString *message = NSLocalizedString(@"Failed to send this file.", nil);
            NSString *title = NSLocalizedString(@"Error!", nil);
            [self showMessage:message withTitle:title];
            return ;
        }
        
        if (MKMNetwork_IsCommunicator(receiver.type)) {
            // personal message, save a copy
            [chatBox insertMessage:iMsg];
        }
    };
    
    [ipc showWithViewController:self completionHandler:handler];
}

- (IBAction)camera:(id)sender {
    NSLog(@"open camera");
    CameraController *camera = [[CameraController alloc] init];
    [self _showImagePickerController:camera];
}

- (IBAction)album:(id)sender {
    NSLog(@"open album");
    AlbumController *album = [[AlbumController alloc] init];
    [self _showImagePickerController:album];
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

- (NSInteger)messageCount {
    return [_conversation numberOfMessage] + 1;
}

- (DIMInstantMessage *)messageAtIndex:(NSInteger)index {
    if (index == 0) {
        DIMCommand *guide = [[DIMCommand alloc] initWithCommand:@"guide"];
        DIMID *admin = [DIMID IDWithID:@"moky@4DnqXWdTV8wuZgfqSCX9GjE2kNq7HJrUgQ"];
        return [[DIMInstantMessage alloc] initWithContent:guide
                                                   sender:admin
                                                 receiver:_conversation.ID
                                                     time:nil];
    }
    return [_conversation messageAtIndex:(index - 1)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //#warning Incomplete implementation, return the number of sections
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //#warning Incomplete implementation, return the number of rows
    
    return [self messageCount];
}

- (NSString *)_identifierForReusableCellAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    DIMInstantMessage *iMsg = [self messageAtIndex:row];
    DIMMessageContent *content = iMsg.content;
    const DIMID *sender = [DIMID IDWithID:iMsg.envelope.sender];
    
    NSString *identifier = @"receivedMsgCell";
    DIMMessageType type = content.type;
    if (type == DIMMessageType_History || type == DIMMessageType_Command) {
        if ([content.command isEqualToString:@"guide"]) {
            // show guide
            identifier = @"guideCell";
        } else {
            // command message
            identifier = @"commandMsgCell";
        }
    } else if ([sender isEqual:_conversation.ID]) {
        // message from conversation target
        identifier = @"receivedMsgCell";
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
    return identifier;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = [self _identifierForReusableCellAtIndexPath:indexPath];
    if ([identifier isEqualToString:@"guideCell"]) {
        return [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    }
    
    // Configure the cell...
    //    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    DIMInstantMessage *iMsg = [self messageAtIndex:row];
    
    MsgCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.msg = iMsg;
    
    if ([identifier isEqualToString:@"sentMsgCell"]) {
        SentMsgCell * sentMsgCell = (SentMsgCell *)cell;
        MessageButton *btn = (MessageButton *)sentMsgCell.infoButton;
        btn.controller = self;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = [self _identifierForReusableCellAtIndexPath:indexPath];
    if ([identifier isEqualToString:@"guideCell"]) {
        return 80;
    }
    
    NSInteger row = indexPath.row;
    DIMInstantMessage *iMsg = [self messageAtIndex:row];
    CGRect bounds = tableView.bounds;
    
    if ([identifier isEqualToString:@"commandMsgCell"]) {
        CGSize size = [CommandMsgCell sizeWithMessage:iMsg bounds:bounds];
        return size.height;
    } else if ([identifier isEqualToString:@"receivedMsgCell"]) {
        CGSize size = [ReceivedMsgCell sizeWithMessage:iMsg bounds:bounds];
        return size.height;
    } else {
        CGSize size = [SentMsgCell sizeWithMessage:iMsg bounds:bounds];
        return size.height;
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"chatDetailSegue"]) {
        
        ChatManageTableViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = _conversation;
        
    } else if ([segue.identifier isEqualToString:@"termsSegue"]) {
        
        Client *client = [Client sharedInstance];
        
        // show terms
        NSString *urlString = client.termsAPI;
        WebViewController *web = [segue visibleDestinationViewController];
        web.url = [NSURL URLWithString:urlString];
        web.title = NSLocalizedString(@"Terms", nil);
        
    }
}

@end
