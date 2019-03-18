//
//  MessageProcessor.m
//  DIMClient
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSObject+JsON.h"
#import "NSDate+Extension.h"
#import "NSNotificationCenter+Extension.h"

#import "Client.h"
#import "Facebook+Register.h"

#import "MessageProcessor+GroupCommand.h"

#import "MessageProcessor.h"

/**
 Get full filepath to Documents Directory
 
 @param ID - account ID
 @param filename - "messages.plist"
 @return "Documents/.dim/{address}/messages.plist"
 */
static inline NSString *full_filepath(const DIMID *ID, NSString *filename) {
    assert(ID.isValid);
    // base directory: Documents/.dim/{address}
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".dim"];
    const DIMAddress *addr = ID.address;
    if (addr) {
        dir = [dir stringByAppendingPathComponent:(NSString *)addr];
    }
    
    // check base directory exists
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir isDirectory:nil]) {
        NSError *error = nil;
        // make sure directory exists
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                       attributes:nil error:&error];
        assert(!error);
    }
    
    // build filepath
    return [dir stringByAppendingPathComponent:filename];
}

static inline NSArray *load_message(const DIMID *ID) {
    NSArray *array = nil;
    NSString *path = full_filepath(ID, @"messages.plist");
    if (file_exists(path)) {
        array = [NSArray arrayWithContentsOfFile:path];
    }
    return array;
}

static inline BOOL save_message(NSArray *messages, const DIMID *ID) {
    NSString *path = full_filepath(ID, @"messages.plist");
    NSLog(@"save path: %@", path);
    return [messages writeToFile:path atomically:YES];
}

static inline BOOL remove_messages(const DIMID *ID) {
    NSString *path = full_filepath(ID, @"messages.plist");
    return remove_file(path);
}

static inline BOOL clear_messages(const DIMID *ID) {
    NSString *path = full_filepath(ID, @"messages.plist");
    NSArray *empty = [[NSArray alloc] init];
    return [empty writeToFile:path atomically:YES];
}

static inline NSMutableDictionary *scan_messages(void) {
    NSMutableDictionary *mDict = [[NSMutableDictionary alloc] init];
    
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".dim"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *de = [fm enumeratorAtPath:dir];
    
    Facebook *fb = [Facebook sharedInstance];
    
    NSString *addr;
    NSArray *array;
    
    const DIMID *ID;
    DIMAddress *address;
    
    NSString *path;
    while (path = [de nextObject]) {
        if ([path hasSuffix:@"/messages.plist"]) {
            addr = [path substringToIndex:(path.length - 15)];
            address = [DIMAddress addressWithAddress:addr];
//            if (!MKMNetwork_IsPerson(address.network) &&
//                !MKMNetwork_IsGroup(address.network)) {
//                // ignore
//                continue;
//            }
            
            path = [dir stringByAppendingPathComponent:path];
            array = [NSArray arrayWithContentsOfFile:path];
            NSLog(@"loaded %lu message(s) from %@", array.count, path);
            
            ID = [fb IDWithAddress:address];
            if (array && ID) {
                NSLog(@"ID: %@", ID);
                [mDict setObject:array forKey:ID];
            } else {
                NSLog(@"failed to load message in path: %@", path);
            }
        }
    }
    
    return mDict;
}

static inline NSMutableArray *time_for_messages(NSArray *messages) {
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:messages.count];
    NSNumber *timestamp;
    NSDate *date;
    NSDate *lastDate = nil;
    NSString *text;
    NSArray *list = [messages copy];
    for (NSDictionary *msg in list) {
        timestamp = [msg objectForKey:@"time"];
        date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp.doubleValue];
        if (lastDate == nil || [date timeIntervalSinceDate:lastDate] > 300) {
            text = NSStringFromDate(date);
            lastDate = date;
        } else {
            text = @"";
        }
        [mArray addObject:text];
    }
    return mArray;
}

typedef NSMutableArray<const DIMInstantMessage *> MessageList;
typedef NSMutableDictionary<const DIMID *, MessageList *> ConversationTable;
typedef NSMutableArray<const DIMID *> ConversationIDList;

@interface MessageProcessor () {
    
    ConversationTable *_chatHistory;
    ConversationIDList *_chatList;
    
    NSMutableDictionary<const DIMID *, NSMutableArray<NSString *> *> *_timesTable;
}

@end

@implementation MessageProcessor

SingletonImplementations(MessageProcessor, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        [self reloadData];
        
        DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
        clerk.conversationDataSource = self;
        clerk.conversationDelegate = self;
    }
    return self;
}

- (void)sortConversationList {
    [_chatList sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        MessageList *table1 = [self->_chatHistory objectForKey:obj1];
        MessageList *table2 = [self->_chatHistory objectForKey:obj2];
        const DIMInstantMessage *msg1 = table1.lastObject;
        const DIMInstantMessage *msg2 = table2.lastObject;
        NSNumber *time1 = [msg1 objectForKey:@"time"];
        NSNumber *time2 = [msg2 objectForKey:@"time"];
        return [time2 compare:time1];
    }];
}

- (void)setChatHistory:(NSMutableDictionary *)dict {
    _chatHistory = dict;
    _chatList = [dict.allKeys mutableCopy];
    [self sortConversationList];
    
    _timesTable = [[NSMutableDictionary alloc] init];
}

- (BOOL)reloadData {
    NSMutableDictionary *dict = scan_messages();
    [self setChatHistory:dict];
    return YES;
}

- (NSInteger)numberOfConversations {
    return _chatList.count;
}

- (DIMConversation *)conversationAtIndex:(NSInteger)index {
    const DIMID *ID = [_chatList objectAtIndex:index];
    return DIMConversationWithID(ID);
}

- (BOOL)removeConversationAtIndex:(NSInteger)index {
    DIMConversation *chatBox = [self conversationAtIndex:index];
    return [self removeConversation:chatBox];
}

- (BOOL)removeConversation:(DIMConversation *)chatBox {
    const DIMID *ID = chatBox.ID;
    NSLog(@"clear conversation for %@", ID);
    [_chatHistory removeObjectForKey:ID];
    return remove_messages(ID);
}

- (BOOL)clearConversationAtIndex:(NSInteger)index {
    DIMConversation *chatBox = [self conversationAtIndex:index];
    return [self clearConversation:chatBox];
}

- (BOOL)clearConversation:(DIMConversation *)chatBox {
    const DIMID *ID = chatBox.ID;
    NSLog(@"clear conversation for %@", ID);
    [_chatHistory removeObjectForKey:ID];
    return clear_messages(ID);
}

#pragma mark DIMConversationDataSource

// get message count in the conversation
- (NSInteger)numberOfMessagesInConversation:(const DIMConversation *)chatBox {
    const DIMID *ID = chatBox.ID;
    
    MessageList *list = [_chatHistory objectForKey:ID];
    if (!list) {
        // TODO: load data from local storage
        NSArray *array = load_message(ID);
        if (array) {
            list = [array mutableCopy];
            [_chatHistory setObject:list forKey:ID];
        }
    }
    
    return list.count;
}

// get message at index of the conversation
- (DIMInstantMessage *)conversation:(const DIMConversation *)chatBox messageAtIndex:(NSInteger)index {
    const DIMID *ID = chatBox.ID;
    
    MessageList *list = [_chatHistory objectForKey:ID];
    if (!list) {
        // TODO: load data from local storage
        NSArray *array = load_message(ID);
        if (array) {
            list = [array mutableCopy];
            [_chatHistory setObject:list forKey:ID];
        }
    }
    
    DIMInstantMessage *iMsg = nil;
    if (list.count > index) {
        iMsg = [DIMInstantMessage messageWithMessage:[list objectAtIndex:index]];
    } else {
        NSAssert(false, @"out of data");
    }
    
    NSMutableArray *timeList = [_timesTable objectForKey:ID];
    if (timeList.count < list.count) {
        timeList = time_for_messages(list);
        [_timesTable setObject:timeList forKey:ID];
    }
    [iMsg setObject:[timeList objectAtIndex:index] forKey:@"timeTag"];
    
    return iMsg;
}

#pragma mark DIMConversationDelegate

// Conversation factory
- (DIMConversation *)conversationWithID:(const DIMID *)ID {
    DIMEntity *entity = nil;
    if (MKMNetwork_IsCommunicator(ID.type)) {
        entity = DIMAccountWithID(ID);
    } else if (MKMNetwork_IsGroup(ID.type)) {
        entity = DIMGroupWithID(ID);
    }
    
    if (entity) {
        // create new conversation with entity (Account/Group)
        DIMConversation *chatBox;
        chatBox = [[DIMConversation alloc] initWithEntity:entity];
        chatBox.dataSource = self;
        chatBox.delegate = self;
        return chatBox;
    }
    NSAssert(false, @"failed to create conversation with ID: %@", ID);
    return nil;
}

// save the new message to local storage
- (BOOL)conversation:(const DIMConversation *)chatBox insertMessage:(const DIMInstantMessage *)iMsg {
    const DIMID *ID = chatBox.ID;
    
    // system command
    DIMMessageContent *content = iMsg.content;
    if (content.type == DIMMessageType_Command) {
        NSString *command = content.command;
        NSLog(@"command: %@", command);
        
        // TODO: parse & execute system command
        // ...
        return YES;
    } else if (content.type == DIMMessageType_History) {
        const DIMID *groupID = [DIMID IDWithID:content.group];
        if (groupID) {
            const DIMID *sender = [DIMID IDWithID:iMsg.envelope.sender];
            if (![self processGroupCommand:content commander:sender]) {
                NSLog(@"group comment error: %@", content);
                return NO;
            }
        }
    }
    
    // TODO: save message in local storage,
    //       if the chat box is visiable, call it to reload data
    BOOL newConvers = NO;
    
    MessageList *list = [_chatHistory objectForKey:ID];
    if (!list) {
        newConvers = YES;
        list = [[MessageList alloc] init];
        [_chatHistory setObject:list forKey:ID];
    }
    
    [list addObject:iMsg];
    // Burn After Reading
    while (list.count > MAX_MESSAGES_SAVED_COUNT) {
        [list removeObjectAtIndex:0];
    }
    
    if (save_message(list, ID)) {
        NSLog(@"new message for %@ saved", ID);
        [NSNotificationCenter postNotificationName:kNotificationName_MessageUpdated object:self];
        return YES;
    } else {
        NSLog(@"failed to save new message for ID: %@", ID);
        return NO;
    }
}

@end
