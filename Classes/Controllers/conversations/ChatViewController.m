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
#import "GuideCell.h"
#import "TimeCell.h"
#import "ReceiveMessageCell.h"
#import "SentMessageCell.h"
#import "CommandMessageCell.h"
#import "ProfileTableViewController.h"
#import "ChatManageTableViewController.h"
#import "ChatViewController.h"
#import "ZoomInViewController.h"

#define TOP_NAVIGATION_BAR_HEIGHT 64.0
#define BOTTOM_TAB_BAR_HEIGHT 46.0

@interface ChatViewController ()<UITextViewDelegate> {
    
    UIView *_textViewBg;
    UITextView *_textView;
    CATextLayer *_textViewPlaceholderLayer;
    UIButton *_addButton;
    UIButton *_submitButton;
    
    BOOL _scrolledToBottom;
    BOOL _adjustingTableViewFrame;
}

@property(nonatomic, strong) UIView *textViewContainer;
@property(nonatomic, readwrite) CGRect keyboardFrame;

@end

@implementation ChatViewController

- (void)dealloc{
    
    self.messagesTableView.delegate = nil;
    self.messagesTableView.dataSource = nil;
    
    @try {
        [_textView removeObserver:self forKeyPath:@"contentSize"];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"•••" style:UIBarButtonItemStylePlain target:self action:@selector(didPressMoreButton:)];
    self.view.backgroundColor = [UIColor colorNamed:@"ViewBackgroundColor"];
    
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height - [self textViewContainerHeight];
    
    self.messagesTableView = [[UITableView alloc] initWithFrame:CGRectMake(x, y, width, height) style:UITableViewStylePlain];
    self.messagesTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.messagesTableView.delegate = self;
    self.messagesTableView.dataSource = self;
    self.messagesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.messagesTableView registerClass:[SentMessageCell class] forCellReuseIdentifier:@"sentMsgCell"];
    [self.messagesTableView registerClass:[ReceiveMessageCell class] forCellReuseIdentifier:@"receivedMsgCell"];
    [self.messagesTableView registerClass:[CommandMessageCell class] forCellReuseIdentifier:@"commandMsgCell"];
    [self.messagesTableView registerClass:[TimeCell class] forCellReuseIdentifier:@"timeCell"];
    [self.messagesTableView registerClass:[GuideCell class] forCellReuseIdentifier:@"guideCell"];
    [self.view addSubview:self.messagesTableView];
    
    [self initInputContainer];
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
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = _conversation.title;
    _adjustingTableViewFrame = NO;
    NSLog(@"title: %@", self.title);
    
    [self addKeyboardObserver];
    [self addDataObserver];
    
    _scrolledToBottom = NO;
}

-(void)addDataObserver{
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(onMessageSent:)
                                 name:kNotificationName_MessageSent
                               object:nil];
    [NSNotificationCenter addObserver:self
                             selector:@selector(onSendMessageFailed:)
                                 name:kNotificationName_SendMessageFailed
                               object:nil];;
    
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

-(void)removeDataObserver{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationName_MessageSent object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationName_SendMessageFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationName_MessageUpdated object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationName_MessageCleaned object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationName_GroupMembersUpdated object:nil];
}

-(void)addKeyboardObserver{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

-(void)removeKeyboardObserver{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
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

#pragma mark - kvo

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _textView && [keyPath isEqualToString:@"contentSize"]) {
        [self adjustTextViewFrameWhenContentSizeChanged];
    }
}

- (void)adjustTextViewFrameWhenContentSizeChanged {
    
    CGFloat containerHeight = [self textViewContainerHeight];
    CGSize size = _textView.contentSize;
    size.height += 10;
    if (size.height < containerHeight) {
        size.height = containerHeight;
    }
    else if (size.height > 100) {
        size.height = 100;
    }
    CGRect rect = _textViewContainer.frame;
    rect.size.height = size.height;
    
    if (CGRectGetMinY(_keyboardFrame) < CGRectGetHeight(self.view.bounds)) {
        rect.origin.y = CGRectGetMinY(_keyboardFrame) - CGRectGetHeight(rect);
    }
    
    _textViewContainer.frame = rect;
    
    CGFloat height = rect.size.height - _textViewBg.frame.origin.y * 2;
    _textViewBg.frame = CGRectMake(_textViewBg.frame.origin.x, _textViewBg.frame.origin.y, _textViewBg.frame.size.width, height);
    _textView.frame = CGRectMake(_textView.frame.origin.x, _textView.frame.origin.y, _textView.frame.size.width, height);
}


#pragma mark - UIKeyboard Notification
- (void)keyboardWillShow:(NSNotification *)o {
    [self adjustTextViewFrameWhenRecieveKeyboardNotification:o];
}

- (void)keyboardWillHide:(NSNotification *)o {
    [self adjustTextViewFrameWhenRecieveKeyboardNotification:o];
}

- (void)keyboardWillChangeFrame:(NSNotification *)o {
    [self adjustTextViewFrameWhenRecieveKeyboardNotification:o];
}

- (void)adjustTextViewFrameWhenRecieveKeyboardNotification:(NSNotification *)o {
    
    CGFloat duration = [[[o userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions curve = [[[o userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    _keyboardFrame = [[[o userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardFrame = [self.view convertRect:_keyboardFrame fromView:self.view.window];
    [self adjustTextViewFrame:duration animationOptions:curve];
}

- (void)adjustTextViewFrame:(CGFloat)duration animationOptions:(UIViewAnimationOptions)options {
    
    NSLog(@"Adjust text view frame");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopAjustTableView) object:nil];
    _adjustingTableViewFrame = YES;
    
    CGRect tableViewRect = self.messagesTableView.frame;
    CGRect textViewRect = _textViewContainer.frame;
    if (CGRectGetMinY(_keyboardFrame) >= CGRectGetHeight(self.view.bounds)) {
        textViewRect.origin.y = CGRectGetHeight(self.view.bounds) - _textViewContainer.frame.size.height;
        tableViewRect.size.height = CGRectGetHeight(self.view.bounds) - _textViewContainer.frame.size.height;
    } else {
        textViewRect.origin.y = CGRectGetMinY(_keyboardFrame) - CGRectGetHeight(textViewRect);
        tableViewRect.size.height = CGRectGetMinY(textViewRect);
    }
    
    if(!CGRectEqualToRect(_textViewContainer.frame, textViewRect)){
        
        [UIView animateWithDuration:duration delay:0 options:options animations:^{
            self.textViewContainer.frame = textViewRect;
            self.messagesTableView.frame = tableViewRect;
            
        } completion:^(BOOL finished) {
            
            NSLog(@"%.2f, %.2f", self.messagesTableView.contentOffset.x, self.messagesTableView.contentOffset.y);
            if (CGRectGetMinY(self.keyboardFrame) < CGRectGetHeight(self.view.bounds)) {
                [self scrollToBottom:YES];
            }
            
            [self performSelector:@selector(stopAjustTableView) withObject:nil afterDelay:0.5];
        }];
    }
}

-(void)stopAjustTableView{
    
    _adjustingTableViewFrame = NO;
}

-(void)scrollToBottom:(BOOL)animated{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopAjustTableView) object:nil];
    
    _adjustingTableViewFrame = YES;
    CGFloat offsetY = self.messagesTableView.contentSize.height - self.messagesTableView.bounds.size.height;
    
    if(offsetY <= 0){
        return;
    }
    
    if(offsetY < TOP_NAVIGATION_BAR_HEIGHT * -1){
        offsetY = TOP_NAVIGATION_BAR_HEIGHT * -1;
    }
    
    [self.messagesTableView setContentOffset:CGPointMake(0.0, offsetY) animated:animated];
    
    [self performSelector:@selector(stopAjustTableView) withObject:nil afterDelay:1.0];
}

#pragma mark - scroll view delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if(scrollView == self.messagesTableView && _adjustingTableViewFrame == NO && [_textView isFirstResponder]){
        [_textView resignFirstResponder];
    }
}

#pragma mark - UITextView delegate

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    if([text isEqualToString:@"\n"]){
        [self send];
        return NO;
    }
    
    return YES;
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView{
    return YES;
}

-(void)send{
    
    NSString *text = _textView.text;
    if (text == nil || text.length == 0) {
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
//    for (; index < count; ++index) {
//        iMsg = [_conversation messageAtIndex:index];
//        msgTime = [[iMsg objectForKey:@"time"] doubleValue];
//        if (msgTime - lastTime > 300) {
//            timeTag = time_string(msgTime);
//            [iMsg setObject:timeTag forKey:@"timeTag"];
//            lastTime = msgTime;
//        }
//    }
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
        GuideCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        cell.delegate = self;
        return cell;
    }
    
    if([identifier isEqualToString:@"timeCell"]){
        TimeCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        return cell;
    }
    
    NSInteger row = indexPath.row;
    DIMInstantMessage *iMsg = [self messageAtIndex:row];
    
    if([identifier isEqualToString:@"commandMsgCell"]){
        CommandMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        cell.msg = iMsg;
        cell.delegate = self;
        return cell;
    }
    
    if ([identifier isEqualToString:@"sentMsgCell"]) {
        SentMessageCell *cell  = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        cell.msg = iMsg;
        cell.delegate = self;
        return cell;
    }
    
    if ([identifier isEqualToString:@"receivedMsgCell"]) {
        ReceiveMessageCell *cell  = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        cell.msg = iMsg;
        cell.delegate = self;
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = [self _identifierForReusableCellAtIndexPath:indexPath];
    
    NSInteger row = indexPath.row;
    DIMInstantMessage *iMsg = [self messageAtIndex:row];
    CGRect bounds = tableView.bounds;
    
    CGFloat height = 0.0;
    if ([identifier isEqualToString:@"commandMsgCell"]) {
        CGSize size = [CommandMessageCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    } else if ([identifier isEqualToString:@"receivedMsgCell"]) {
        CGSize size = [ReceiveMessageCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    } else if ([identifier isEqualToString:@"guideCell"]) {
        CGSize size = [GuideCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    } else if ([identifier isEqualToString:@"timeCell"]) {
        CGSize size = [TimeCell sizeWithMessage:iMsg bounds:bounds];
        height = size.height;
    } else {
        CGSize size = [SentMessageCell sizeWithMessage:iMsg bounds:bounds];
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
    
    ChatManageTableViewController *controller = [[ChatManageTableViewController alloc] init];
    controller.conversation = self.conversation;
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)didPressAgreementButton:(id)sender{
    
    Client *client = [Client sharedInstance];
    NSString *urlString = client.termsAPI;
    WebViewController *web = [[WebViewController alloc] init];
    web.url = [NSURL URLWithString:urlString];
    web.title = NSLocalizedString(@"Terms", nil);
    [self.navigationController pushViewController:web animated:YES];
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

#pragma mark MessageCellDelegate

-(void)messageCell:(MessageCell *)cell showImage:(UIImage *)image{
    
    ZoomInViewController *controller = [[ZoomInViewController alloc] init];
    controller.image = image;
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

-(void)messageCell:(MessageCell *)cell openUrl:(NSURL *)url{
    
    WebViewController *web = [[WebViewController alloc] init];
    web.hidesBottomBarWhenPushed = YES;
    web.url = url;
    [self.navigationController pushViewController:web animated:YES];
}

@end
