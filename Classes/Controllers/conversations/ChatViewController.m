//
//  ChatViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSData+Extension.h"
#import "NSDate+Extension.h"
#import "UIColor+Extension.h"
#import "NSString+Extension.h"
#import "NSNotificationCenter+Extension.h"
#import "UIStoryboardSegue+Extension.h"
#import "UIButton+Extension.h"
#import "UIImage+Extension.h"
#import "UIScrollView+Extension.h"
#import "UIViewController+Extension.h"
#import "WebViewController.h"
#import "ImagePickerController.h"
#import "MessageProcessor.h"
#import "Client.h"
#import "MsgCell.h"
#import "ProfileTableViewController.h"
#import "ChatManageTableViewController.h"
#import "ChatViewController.h"

static inline NSString *time_string(NSTimeInterval timestamp) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
    NSDate *days_ago = [[[NSDate date] dateBySubtractingDays:7] dateAtStartOfDay];
    if ([date isToday]) {
        [dateFormatter setDateFormat:@"a HH:mm"];
    } else if ([date isYesterday]) {
        [dateFormatter setDateFormat:@"a HH:mm"];
        NSString *string = [dateFormatter stringFromDate:date];
        NSString *format = NSLocalizedString(@"Yesterday %@" ,@"title");
        return [NSString stringWithFormat:format, string];
    } else if ([date isLaterThanDate:days_ago]) {
        [dateFormatter setDateFormat:@"EEEE HH:mm"];
    } else {
        [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm"];
    }
    return [dateFormatter stringFromDate:date];
}

@interface ChatViewController ()<UITextViewDelegate> {
    
    CGRect _tableFrame;
    CGRect _containerFrame;
    UIView *_textViewBg;
    UITextView *_textView;
    CATextLayer *_textViewPlaceholderLayer;
    UIButton *_addButton;
    UIButton *_submitButton;
    CGRect _keyboardFrame;
    
    BOOL _scrolledToBottom;
}

@property(nonatomic, strong) UIView *textViewContainer;

@end

@implementation ChatViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"•••" style:UIBarButtonItemStylePlain target:self action:@selector(didPressMoreButton:)];
    
    CGFloat x = 0.0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = [self textViewContainerHeight];
    CGFloat y = self.view.bounds.size.height - height;
    
    [self initInputContainer];
    
    height = y;
    y = 0.0;
    self.messagesTableView = [[UITableView alloc] initWithFrame:CGRectMake(x, y, width, height) style:UITableViewStylePlain];
    self.messagesTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.messagesTableView.delegate = self;
    self.messagesTableView.dataSource = self;
    self.messagesTableView.backgroundColor = [UIColor grayColor];
    self.messagesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.messagesTableView registerClass:[SentMsgCell class] forCellReuseIdentifier:@"sentMsgCell"];
    [self.messagesTableView registerClass:[ReceivedMsgCell class] forCellReuseIdentifier:@"receivedMsgCell"];
    [self.messagesTableView registerClass:[CommandMsgCell class] forCellReuseIdentifier:@"commandMsgCell"];
    [self.messagesTableView registerClass:[TimeCell class] forCellReuseIdentifier:@"timeCell"];
    [self.messagesTableView registerClass:[GuideCell class] forCellReuseIdentifier:@"guideCell"];
    [self.view addSubview:self.messagesTableView];
}

-(CGFloat)textViewContainerHeight{
    return 50.0;
}

-(void)initInputContainer{
    
    CGFloat textViewContainerHeight = [self textViewContainerHeight];
    _keyboardFrame = CGRectMake(0, CGRectGetHeight(self.view.bounds), 0, 0);
    
    _textViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - textViewContainerHeight, CGRectGetWidth(self.view.bounds), textViewContainerHeight)];
    _textViewContainer.backgroundColor = [UIColor colorWithHexString:@"f8f8f8"];
    _textViewContainer.userInteractionEnabled = YES;
    [self.view addSubview:_textViewContainer];
    
    CGFloat width = 26.0;
    CGFloat height = textViewContainerHeight;
    CGFloat x = self.view.bounds.size.width - 10.0 - width;
    CGFloat y = (CGRectGetHeight(_textViewContainer.bounds) - height) / 2;
    
    _addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    _addButton.frame = CGRectMake(x, y, width, height);
    [_addButton addTarget:self action:@selector(addButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_textViewContainer addSubview:_addButton];
    
    x = 10.0;
    width = CGRectGetMinX(_addButton.frame) - x * 2;
    height = 36.0;
    y = (_textViewContainer.bounds.size.height - height) / 2;
    _textViewBg = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    _textViewBg.backgroundColor = [UIColor whiteColor];
    _textViewBg.layer.cornerRadius = height / 2;
    _textViewBg.layer.masksToBounds = YES;
    _textViewBg.layer.borderColor = [UIColor colorWithHexString:@"cdcdcd"].CGColor;
    _textViewBg.layer.borderWidth = 0.5;
    [_textViewContainer addSubview:_textViewBg];
    
    x = CGRectGetMinX(_textViewBg.frame) + 10.0;
    width = _textViewBg.bounds.size.width - 20.0;
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    _textView.returnKeyType = UIReturnKeySend;
    _textView.enablesReturnKeyAutomatically = YES;
    _textView.showsVerticalScrollIndicator = NO;
    _textView.autocorrectionType = UITextAutocorrectionTypeNo;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.scrollsToTop = NO;
    _textView.font = [UIFont systemFontOfSize:17.0];
    _textView.delegate = self;
    [_textViewContainer addSubview:_textView];
    
    _textViewPlaceholderLayer = [[CATextLayer alloc] init];
    _textViewPlaceholderLayer.string = NSLocalizedString(@"", @"title");
    _textViewPlaceholderLayer.frame = CGRectMake(8, 8, 220, 20);
    _textViewPlaceholderLayer.fontSize = 14.0;
    _textViewPlaceholderLayer.foregroundColor = [[UIColor colorWithHexString:@"999999"] CGColor];
    _textViewPlaceholderLayer.contentsScale = [UIScreen mainScreen].scale;
    [_textView.layer addSublayer:_textViewPlaceholderLayer];
    
    [_textView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _textViewContainer.frame.size.width, 0.5)];
    line.backgroundColor = [UIColor colorWithHexString:@"aaaaaa"];
    [_textViewContainer addSubview:line];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = _conversation.title;
    NSLog(@"title: %@", self.title);
    
    _tableFrame = _messagesTableView.frame;
    _containerFrame = _textViewContainer.frame;
    
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
    
    _scrolledToBottom = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    if (!_scrolledToBottom) {
        [self.messagesTableView scrollsToBottom];
        _scrolledToBottom = YES;
    }

}

- (void)onMessageUpdated:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_MessageUpdated]) {
        DIMID *ID = DIMIDWithString([info objectForKey:@"ID"]);
        if ([_conversation.ID isEqual:ID]) {
            [self scrollAfterInsertNewMessage];
        }
    }
}

- (void)onMessageCleaned:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    
    if ([name isEqual:kNotificationName_MessageCleaned]) {
        DIMID *ID = DIMIDWithString([info objectForKey:@"ID"]);
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

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGRect tableRect = _tableFrame;
    tableRect.size.height -= keyboardSize.height;
    
    CGRect trayRect = _textViewContainer.frame;
    trayRect.origin.y -= keyboardSize.height;
    
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.messagesTableView.frame = tableRect;
        self.textViewContainer.frame = trayRect;
    } completion:^(BOOL finished) {
        
        if(finished){
            [self.messagesTableView scrollsToBottom];
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.messagesTableView.frame = self->_tableFrame;
        self.textViewContainer.frame = self->_containerFrame;
    }];
}

- (void)_hideKeyboard {
    [_textView resignFirstResponder];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self _hideKeyboard];
}

- (IBAction)send:(id)sender {
    NSString *text = _textView.text;
    if (text.length == 0) {
        NSLog(@"empty");
        return;
    }

    DIMConversation *chatBox = _conversation;
    DIMID *receiver = chatBox.ID;
    NSLog(@"send text: %@ -> %@", text, receiver);
    
    // create message content
    DIMContent *content;
    content = [[DIMTextContent alloc] initWithText:text];
    
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
    
    if (MKMNetwork_IsUser(receiver.type)) {
        [self.conversation insertMessage:iMsg];
    }
    
    _textView.text = @"";
}

- (void)_showImagePickerController:(ImagePickerController *)ipc {
    DIMConversation *chatBox = _conversation;
    DIMID *receiver = chatBox.ID;
    
    // completion handler
    ImagePickerControllerCompletionHandler handler;
    handler = ^(UIImage * _Nullable image,
                NSString *path,
                NSDictionary<UIImagePickerControllerInfoKey,id> *info,
                UIImagePickerController *ipc) {
        
        NSLog(@"pick image: %@, path: %@", image, path);
        
        // 1. build message content
        DIMContent *content = nil;
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
            content = [[DIMImageContent alloc] initWithImageData:data filename:filename];
            [content setObject:@(data.length) forKey:@"length"];
            [content setObject:[small base64Encode] forKey:@"thumbnail"];
        } else {
            // movie message
            NSData *data = [NSData dataWithContentsOfFile:path];
            content = [[DIMVideoContent alloc] initWithVideoData:data filename:@"video.mp4"];
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
        
        if (MKMNetwork_IsUser(receiver.type)) {
            // personal message, save a copy
            [chatBox insertMessage:iMsg];
        }
    };
    
    [ipc showWithViewController:self completionHandler:handler];
}

- (void)camera:(id)sender {
    NSLog(@"open camera");
    CameraController *camera = [[CameraController alloc] init];
    [self _showImagePickerController:camera];
}

- (void)album:(id)sender {
    NSLog(@"open album");
    AlbumController *album = [[AlbumController alloc] init];
    [self _showImagePickerController:album];
}

- (void)onMessageSent:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    DIMInstantMessage *msg = [info objectForKey:@"message"];
    msg = DKDInstantMessageFromDictionary(msg);
    NSLog(@"%@: %@", name, msg);
    // TODO: mark the message sent
}

- (void)onSendMessageFailed:(NSNotification *)notification {
    NSString *name = notification.name;
    NSDictionary *info = notification.userInfo;
    DIMInstantMessage *msg = [info objectForKey:@"message"];
    msg = DKDInstantMessageFromDictionary(msg);
    NSError *error = [info objectForKey:@"error"];
    NSLog(@"%@: %@, error: %@", name, msg, error);
    // TODO: mark the message failed for trying again
}

- (NSInteger)messageCount {
    NSInteger count = [_conversation numberOfMessage];
    // create time tag
    DIMInstantMessage *iMsg;
    NSString *timeTag;
    NSTimeInterval lastTime = 0, msgTime;
    // 1. search last tag
    NSInteger index = count - 1;
    for (; index >= 0; --index) {
        iMsg = [_conversation messageAtIndex:index];
        timeTag = [iMsg objectForKey:@"timeTag"];
        if (timeTag) {
//            lastTime = [[iMsg objectForKey:@"time"] doubleValue];
//            break;
            // FIXME: some time tags needs to be update when the day passed
            [iMsg removeObjectForKey:@"timeTag"];
        }
    }
    if (index < 0) {
        // not found
        index = 0;
    }
    // 2. create tag for the rest messages
    for (; index < count; ++index) {
        iMsg = [_conversation messageAtIndex:index];
        msgTime = [[iMsg objectForKey:@"time"] doubleValue];
        if (msgTime - lastTime > 300) {
            timeTag = time_string(msgTime);
            [iMsg setObject:timeTag forKey:@"timeTag"];
            lastTime = msgTime;
        }
    }
    // the first message is 'guide'
    return count + 1;
}

- (DIMInstantMessage *)messageAtIndex:(NSInteger)index {
    if (index == 0) {
        DIMCommand *guide = [[DIMCommand alloc] initWithCommand:@"guide"];
        DIMID *admin = DIMIDWithString(@"moky@4DnqXWdTV8wuZgfqSCX9GjE2kNq7HJrUgQ");
        return DKDInstantMessageCreate(guide, admin, _conversation.ID, nil);
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
    DIMLocalUser *user = client.currentUser;
    
    DIMInstantMessage *iMsg = [self messageAtIndex:row];
    DIMContent *content = iMsg.content;
    DIMID *sender = DIMIDWithString(iMsg.envelope.sender);
    
    NSString *identifier = @"receivedMsgCell";
    DKDContentType type = content.type;
    if (type == DKDContentType_History || type == DKDContentType_Command) {
        if ([[(DIMCommand *)content command] isEqualToString:@"guide"]) {
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
    
    NSInteger row = indexPath.row;
    DIMInstantMessage *iMsg = [self messageAtIndex:row];
    CGRect bounds = tableView.bounds;
    
    CGFloat height = 0.0;
    if ([identifier isEqualToString:@"commandMsgCell"]) {
        CGSize size = [CommandMsgCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    } else if ([identifier isEqualToString:@"receivedMsgCell"]) {
        CGSize size = [ReceivedMsgCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    } else if ([identifier isEqualToString:@"guideCell"]) {
        CGSize size = [GuideCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    } else {
        CGSize size = [SentMsgCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    }
    
    return height;
}

#pragma mark - Navigation

-(void)addButtonAction:(id)sender{
    
    UIAlertController *actionsheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Camera", @"title") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self camera:actionsheet];
    }];
    
    UIAlertAction *albumAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Album", @"title") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self album:actionsheet];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"title") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [albumAction setValue:[UIImage imageNamed:@"sharemore_pic"] forKey:@"image"];
    [cameraAction setValue:[UIImage imageNamed:@"sharemore_video"] forKey:@"image"];
    
    [actionsheet addAction:cameraAction];
    [actionsheet addAction:albumAction];
    [actionsheet addAction:cancelAction];
    [self presentViewController:actionsheet animated:YES completion:nil];
}

-(void)didPressMoreButton:(id)sender{
    
    
}

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
        
    } else if ([segue.identifier isEqualToString:@"profileSegue"]) {
        
        MsgCell *cell = sender;
        DIMID *ID = DIMIDWithString(cell.msg.envelope.sender);
        
        ProfileTableViewController *vc = [segue visibleDestinationViewController];
        vc.contact = ID;
        
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [self send:textField];
    return YES;
}

-(void)scrollAfterInsertNewMessage{

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.conversation numberOfMessage] inSection:0];
    
    [self.messagesTableView beginUpdates];
    [self.messagesTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.messagesTableView endUpdates];

    if(self.messagesTableView.contentOffset.y + self.messagesTableView.bounds.size.height > self.messagesTableView.contentSize.height - 100){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.messagesTableView scrollsToBottom:YES];
        });
    }
}

@end
