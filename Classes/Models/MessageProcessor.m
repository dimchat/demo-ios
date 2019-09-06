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

#import "MessageProcessor.h"

#import "MessageProcessor.h"

static inline NSMutableArray *time_for_messages(NSArray *messages) {
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:messages.count];
    NSNumber *timestamp;
    NSDate *date;
    NSDate *lastDate = nil;
    NSString *text;
    messages = [messages copy];
    for (NSDictionary *msg in messages) {
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

typedef NSMutableArray<DIMInstantMessage *> MessageList;
typedef NSMutableDictionary<DIMID *, MessageList *> ConversationTable;
typedef NSMutableArray<DIMID *> ConversationIDList;

@interface MessageProcessor () {
    
    ConversationTable *_chatHistory;
    ConversationIDList *_chatList;
    
    NSMutableDictionary<DIMID *, NSMutableArray<NSString *> *> *_timesTable;
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
        DIMInstantMessage *msg1 = table1.lastObject;
        DIMInstantMessage *msg2 = table2.lastObject;
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

- (NSString *)timeTagAtIndex:(NSInteger)index forConversationID:(DIMID *)ID {
    
    NSMutableArray *timeList = [_timesTable objectForKey:ID];
    if (timeList.count <= index) {
        // new message appended, update 'timeTag'
        MessageList *list = [_chatHistory objectForKey:ID];
        timeList = time_for_messages(list);
        // FIXME:
        //NSAssert(timeList.count == list.count, @"time tags error: %@", timeList);
        [_timesTable setObject:timeList forKey:ID];
    }
    return [timeList objectAtIndex:index];
}

- (BOOL)reloadData {
    NSArray<DIMConversation *> *conversations = [self allConversations];
    NSMutableDictionary *mDict;
    mDict = [[NSMutableDictionary alloc] initWithCapacity:conversations.count];
    
    NSArray<DIMInstantMessage *> *messages;
    for (DIMConversation *chatBox in conversations) {
        messages = [self messagesInConversation:chatBox];
        NSAssert(messages, @"failed to get messages: %@", chatBox.ID);
        [mDict setObject:messages forKey:chatBox.ID];
    }
    
    [self setChatHistory:mDict];
    return YES;
}

- (NSInteger)numberOfConversations {
    return _chatList.count;
}

- (DIMConversation *)conversationAtIndex:(NSInteger)index {
    DIMID *ID = [_chatList objectAtIndex:index];
    return DIMConversationWithID(ID);
}

- (BOOL)removeConversationAtIndex:(NSInteger)index {
    DIMConversation *chatBox = [self conversationAtIndex:index];
    return [self removeConversation:chatBox];
}

- (BOOL)removeConversation:(DIMConversation *)chatBox {
    BOOL removed = [super removeConversation:chatBox];
    if (removed) {
        DIMID *ID = chatBox.ID;
        NSLog(@"conversation removed: %@", ID);
        [_chatHistory removeObjectForKey:ID];
        [_chatList removeObject:ID];
        [NSNotificationCenter postNotificationName:kNotificationName_MessageCleaned
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
    BOOL cleared = [super clearConversation:chatBox];
    if (cleared) {
        DIMID *ID = chatBox.ID;
        NSLog(@"conversation cleaned: %@", ID);
        [[_chatHistory objectForKey:ID] removeAllObjects];
        [NSNotificationCenter postNotificationName:kNotificationName_MessageCleaned
                                            object:self
                                          userInfo:@{@"ID": ID}];
    }
    return cleared;
}

#pragma mark DIMConversationDataSource

// get message at index of the conversation
- (DIMInstantMessage *)conversation:(DIMConversation *)chatBox messageAtIndex:(NSInteger)index {
    DIMInstantMessage *iMsg = [super conversation:chatBox messageAtIndex:index];
    
    NSString *timeTag = [self timeTagAtIndex:index forConversationID:chatBox.ID];
    [iMsg setObject:timeTag forKey:@"timeTag"];
    
    return iMsg;
}

#pragma mark DIMConversationDelegate

// save the new message to local storage
- (BOOL)conversation:(DIMConversation *)chatBox insertMessage:(DIMInstantMessage *)iMsg {
    if (![super conversation:chatBox insertMessage:iMsg]) {
        return NO;
    }
    
    // check whether the group members info is updated
    DIMID *ID = chatBox.ID;
    if (MKMNetwork_IsGroup(ID.type)) {
        DIMGroup *group = DIMGroupWithID(ID);
        DIMContent *content = iMsg.content;
        // if the group info not found, and this is not an 'invite' command
        //     query group info from the sender
        BOOL needsUpdate = group.founder == nil;
        if (content.type == DKDContentType_History) {
            NSString *command = [(DIMGroupCommand *)content command];
            if ([command isEqualToString:DIMGroupCommand_Invite]) {
                needsUpdate = NO;
            }
        }
        if (needsUpdate) {
            DIMID *sender = DIMIDWithString(iMsg.envelope.sender);
            NSAssert(sender != nil, @"sender error: %@", iMsg);
            
            DIMQueryGroupCommand *query;
            query = [[DIMQueryGroupCommand alloc] initWithGroup:ID];
            
            Client *client = [Client sharedInstance];
            [client sendContent:query to:sender];
        }
    }
    
    [NSNotificationCenter postNotificationName:kNotificationName_MessageUpdated
                                        object:self
                                      userInfo:@{@"ID": ID}];
    return YES;
}

@end
