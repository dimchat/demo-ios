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

//static inline NSArray *load_message(const DIMID *ID) {
//    NSArray *array = nil;
//    NSString *path = full_filepath(ID, @"messages.plist");
//    if (file_exists(path)) {
//        array = [NSArray arrayWithContentsOfFile:path];
//    }
//    return array;
//}

static inline BOOL save_message(NSArray *messages, const DIMID *ID) {
    messages = [messages copy];
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
    NSMutableArray *empty = [[NSMutableArray alloc] init];
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
    NSMutableArray *array;
    
    const DIMID *ID;
    DIMAddress *address;
    
    NSString *path;
    while (path = [de nextObject]) {
        if (![path hasSuffix:@"/messages.plist"]) {
            // no messages
            continue;
        }
        addr = [path substringToIndex:(path.length - 15)];
        address = [DIMAddress addressWithAddress:addr];
        if (MKMNetwork_IsStation(address.network)) {
            // ignore station history
            continue;
        }
        
        path = [dir stringByAppendingPathComponent:path];
        array = [NSMutableArray arrayWithContentsOfFile:path];
        NSLog(@"loaded %lu message(s) from %@", array.count, path);
        
        ID = [fb IDWithAddress:address];
        if (array && ID) {
            NSLog(@"ID: %@", ID);
            [mDict setObject:array forKey:ID];
        } else {
            NSLog(@"failed to load message in path: %@", path);
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
    /*
     These constants are used to indicate how items in a request are ordered,
     from the first one given in a method invocation or function call
     to the last (that is, left to right in code).
     
     Given the function:
     NSComparisonResult f(int a, int b)
     
     If:
     a < b   then return NSOrderedAscending.
     a > b   then return NSOrderedDescending.
     a == b  then return NSOrderedSame.
     */
    NSComparator comparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        MessageList *table1 = [self->_chatHistory objectForKey:obj1];
        MessageList *table2 = [self->_chatHistory objectForKey:obj2];
        const DIMInstantMessage *msg1 = table1.lastObject;
        const DIMInstantMessage *msg2 = table2.lastObject;
        NSNumber *time1 = [msg1 objectForKey:@"time"];
        NSNumber *time2 = [msg2 objectForKey:@"time"];
        NSTimeInterval t1 = [time1 doubleValue];
        NSTimeInterval t2 = [time2 doubleValue];
        if (t1 < t2) {
            return NSOrderedDescending;
        } else if (t1 > t2) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    };
    _chatList = [_chatHistory.allKeys mutableCopy];
    [_chatList sortUsingComparator:comparator];
}

- (void)setChatHistory:(NSMutableDictionary *)dict {
    _chatHistory = dict;
    [self sortConversationList];
    
    _timesTable = [[NSMutableDictionary alloc] init];
}

- (BOOL)insertMessage:(const DIMInstantMessage *)iMsg forConversationID:(const DIMID *)ID {
    
    MessageList *list = [_chatHistory objectForKey:ID];
    if (list.count == 0) {
        // message list empty, create new one, even '_NSArray0'
        list = [[MessageList alloc] init];
        [_chatHistory setObject:list forKey:ID];
    }
    [list addObject:iMsg];
    
    // Burn After Reading
    NSMutableArray *timeList = [_timesTable objectForKey:ID];
    while (list.count > MAX_MESSAGES_SAVED_COUNT) {
        [list removeObjectAtIndex:0];
        if (timeList.count > 0) {
            [timeList removeObjectAtIndex:0];
        } else {
            // FIXME: sometimes this would happen
            //NSAssert(false, @"time list should not be empty here");
        }
    }
    
    if (save_message(list, ID)) {
        NSLog(@"new message for %@ saved", ID);
        [self sortConversationList];
        return YES;
    } else {
        NSLog(@"failed to save new message for ID: %@", ID);
        return NO;
    }
}

- (NSString *)timeTagAtIndex:(NSInteger)index forConversationID:(const DIMID *)ID {
    
    NSMutableArray *timeList = [_timesTable objectForKey:ID];
    if (timeList.count <= index) {
        // new message appended, update 'timeTag'
        MessageList *list = [_chatHistory objectForKey:ID];
        timeList = time_for_messages(list);
        NSAssert(timeList.count == list.count, @"time tags error: %@", timeList);
        [_timesTable setObject:timeList forKey:ID];
    }
    return [timeList objectAtIndex:index];
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
    NSLog(@"remove conversation for %@", ID);
    BOOL removed = remove_messages(ID);
    if (removed) {
        [_chatHistory removeObjectForKey:ID];
        [_chatList removeObject:ID];
        [NSNotificationCenter postNotificationName:kNotificationName_MessageUpdated
                                            object:self
                                          userInfo:@{@"ID": ID}];
    }
    return removed;
}

- (BOOL)clearConversationAtIndex:(NSInteger)index {
    DIMConversation *chatBox = [self conversationAtIndex:index];
    return [self clearConversation:chatBox];
}

- (BOOL)clearConversation:(DIMConversation *)chatBox {
    const DIMID *ID = chatBox.ID;
    NSLog(@"clear conversation for %@", ID);
    BOOL cleared = clear_messages(ID);
    if (cleared) {
        [[_chatHistory objectForKey:ID] removeAllObjects];
        [NSNotificationCenter postNotificationName:kNotificationName_MessageUpdated
                                            object:self
                                          userInfo:@{@"ID": ID}];
    }
    return cleared;
}

#pragma mark DIMConversationDataSource

// get message count in the conversation
- (NSInteger)numberOfMessagesInConversation:(const DIMConversation *)chatBox {
    const DIMID *ID = chatBox.ID;
    
    NSArray *list = [_chatHistory objectForKey:ID];
    return list.count;
}

// get message at index of the conversation
- (DIMInstantMessage *)conversation:(const DIMConversation *)chatBox messageAtIndex:(NSInteger)index {
    const DIMID *ID = chatBox.ID;
    
    NSMutableArray *list = [_chatHistory objectForKey:ID];
    
    DIMInstantMessage *iMsg = nil;
    if (list.count > index) {
        NSDictionary *item = [list objectAtIndex:index];
        iMsg = [DIMInstantMessage messageWithMessage:item];
        if (iMsg != item) {
            // replace InstantMessage object for next access
            [list replaceObjectAtIndex:index withObject:iMsg];
        }
    } else {
        NSAssert(false, @"out of data");
    }
    
    NSString *timeTag = [self timeTagAtIndex:index forConversationID:ID];
    [iMsg setObject:timeTag forKey:@"timeTag"];
    
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
- (BOOL)conversation:(const DIMConversation *)chatBox insertMessage:(DIMInstantMessage *)iMsg {
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
    
    // check whether the group members info is updated
    if (MKMNetwork_IsGroup(ID.type)) {
        DIMGroup *group = DIMGroupWithID(ID);
        if (group.founder == nil) {
            const DIMID *sender = [DIMID IDWithID:iMsg.envelope.sender];
            NSAssert(sender != nil, @"sender error: %@", iMsg);
            
            DIMQueryGroupCommand *query;
            query = [[DIMQueryGroupCommand alloc] initWithGroup:ID];
            
            Client *client = [Client sharedInstance];
            [client sendContent:query to:sender];
        }
    }
    
    if ([self insertMessage:iMsg forConversationID:ID]) {
        [NSNotificationCenter postNotificationName:kNotificationName_MessageUpdated
                                            object:self
                                          userInfo:@{@"ID": ID}];
        return YES;
    } else {
        return NO;
    }
}

@end
