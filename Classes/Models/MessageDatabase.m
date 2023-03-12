//
//  MessageDatabase.m
//  DIMP
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "Facebook+Register.h"
#import "Client.h"
#import "DIMAmanuensis.h"

#import "MessageDatabase.h"

typedef NSMutableArray<id<MKMID>> ConversationListM;

@interface MessageDatabase () {
    
    ConversationListM *_conversationList;
}

@end

@implementation MessageDatabase

OKSingletonImplementations(MessageDatabase, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        
        DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
        clerk.conversationDataSource = self;
        clerk.conversationDelegate = self;
    }
    return self;
}

- (nullable id<DKDInstantMessage>)_lastMessageInConversation:(id<MKMID>)ID {
    NSUInteger count = [self numberOfMessagesInConversation:ID];
    if (count == 0) {
        return nil;
    }
    return [self conversation:ID messageAtIndex:(count - 1)];
}

- (void)sortConversationList {
    NSComparator comparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        id<DKDInstantMessage> msg1 = [self _lastMessageInConversation:obj1];
        id<DKDInstantMessage> msg2 = [self _lastMessageInConversation:obj2];
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
    // sort all conversations
    NSArray *array = [self allConversations];
    NSMutableArray *mArray = [array mutableCopy];
    [mArray sortUsingComparator:comparator];
    _conversationList = mArray;
}

- (NSInteger)numberOfConversations {
    [self sortConversationList];
    return [_conversationList count];
}

- (id<MKMID>)conversationAtIndex:(NSInteger)index {
    return [_conversationList objectAtIndex:index];
}

- (BOOL)removeConversationAtIndex:(NSInteger)index {
    id<MKMID> chatBox = [self conversationAtIndex:index];
    return [self removeConversation:chatBox];
}

- (BOOL)removeConversation:(id<MKMID>)chatBox {
    BOOL removed = [super removeConversation:chatBox];
    if (removed) {
        [_conversationList removeObject:chatBox];
        NSLog(@"conversation removed: %@", chatBox);
    }
    return removed;
}

- (BOOL)clearConversationAtIndex:(NSInteger)index {
    id<MKMID> chatBox = [self conversationAtIndex:index];
    return [self clearConversation:chatBox];
}

- (BOOL)clearConversation:(id<MKMID>)chatBox {
    BOOL cleared = [super clearConversation:chatBox];
    return cleared;
}

#pragma mark DIMConversationDelegate

// save the new message to local storage
- (BOOL)conversation:(id<MKMID>)chatBox insertMessage:(id<DKDInstantMessage>)iMsg {
    if (![super conversation:chatBox insertMessage:iMsg]) {
        NSLog(@"failed to save message: %@", iMsg);
        return NO;
    }
    // sort conversation list
    [self sortConversationList];
    
    return YES;
}

@end
