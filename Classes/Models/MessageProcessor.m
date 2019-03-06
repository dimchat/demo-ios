//
//  MessageProcessor.m
//  DIMClient
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSObject+JsON.h"

#import "Facebook.h"
#import "Client.h"

#import "MessageProcessor.h"

NSString *NSStringFromDate(const NSDate *date) {
    NSTimeInterval delta = [date timeIntervalSinceNow];
    if (delta < 10 && delta > -30) {
        return @"Just now";
    }
    if (delta > -60) {
        return @"Less than 1 minute";
    }
    if (delta > -120) {
        return @"Less than 2 minutes";
    }
    if (delta > -600) {
        return @"Within a few minutes";
    }
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
    }
    if (delta > -36000) {
        [dateFormatter setDateFormat:@"HH:mm"];
        return [dateFormatter stringFromDate:(id)date];
    }
    if (delta > -(3600*24*10)) {
        [dateFormatter setDateFormat:@"MM-dd HH:mm"];
        return [dateFormatter stringFromDate:(id)date];
    }
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    return [dateFormatter stringFromDate:(id)date];
}

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
    DIMAddress *addr = ID.address;
    if (addr) {
        dir = [dir stringByAppendingPathComponent:addr];
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

static inline BOOL clear_message(const DIMID *ID) {
    NSString *path = full_filepath(ID, @"messages.plist");
    return remove_file(path);
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
    
    DIMID *ID;
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
            
            ID = [fb IDWithAddress:address];
            if (array && ID) {
                [mDict setObject:array forKey:ID];
            }
        }
    }
    
    return mDict;
}

typedef NSMutableArray<const DIMInstantMessage *> MessageList;
typedef NSMutableDictionary<const DIMID *, MessageList *> ConversationTable;

@interface MessageProcessor () {
    
    ConversationTable *_chatHistory;
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

- (BOOL)reloadData {
    NSMutableDictionary *dict = scan_messages();
    if ([_chatHistory isEqual:dict]) {
        // nothing changed
        return NO;
    }
    _chatHistory = dict;
    return YES;
}

- (NSInteger)numberOfConversations {
    NSArray *keys = _chatHistory.allKeys;
    return keys.count;
}

- (DIMConversation *)conversationAtIndex:(NSInteger)index {
    NSArray *keys = _chatHistory.allKeys;
    DIMID *ID = [keys objectAtIndex:index];
    return DIMConversationWithID(ID);
}

- (BOOL)clearConversationAtIndex:(NSInteger)index {
    DIMConversation *chatBox = [self conversationAtIndex:index];
    return [self clearConversation:chatBox];
}

- (BOOL)clearConversation:(DIMConversation *)chatBox {
    DIMID *ID = chatBox.ID;
    NSLog(@"clear conversation for %@", ID);
    [_chatHistory removeObjectForKey:ID];
    return clear_message(ID);
}

#pragma mark DIMConversationDataSource

// get message count in the conversation
- (NSInteger)numberOfMessagesInConversation:(const DIMConversation *)chatBox {
    DIMID *ID = chatBox.ID;
    
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
    DIMID *ID = chatBox.ID;
    
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
    
    return iMsg;
}

#pragma mark DIMConversationDelegate

// Conversation factory
- (DIMConversation *)conversationWithID:(const DIMID *)ID {
    DIMEntity *entity = nil;
    if (MKMNetwork_IsCommunicator(ID.type)) {
        entity = MKMAccountWithID(ID);
    } else if (MKMNetwork_IsGroup(ID.type)) {
        entity = MKMGroupWithID(ID);
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
    DIMID *ID = chatBox.ID;
    
    // system command
    DIMMessageContent *content = iMsg.content;
    if (content.type == DIMMessageType_Command) {
        NSString *cmd = content.command;
        NSLog(@"command: %@", cmd);
        
        // TODO: parse & execute system command
        // ...
        return YES;
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
        Client *client = [Client sharedInstance];
        [client postNotificationName:kNotificationName_MessageUpdated object:self];
        return YES;
    } else {
        return NO;
    }
}

@end
