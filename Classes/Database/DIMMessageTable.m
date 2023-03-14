// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
//
//  DIMMessageTable.m
//  DIMP
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMSDK/DIMSDK.h>

#import "LocalDatabaseManager.h"
#import "DIMMessageTable.h"

typedef NSMutableArray<id<MKMID>> ConversationList;
typedef NSMutableArray<id<DKDInstantMessage>> MessageList;
typedef NSMutableDictionary<id<MKMID>, MessageList *> MessageTable;

@interface DIMMessageTable ()

@property(nonatomic, strong) MessageTable *caches;

@property(nonatomic, strong) ConversationList *conversations;

@property(nonatomic, strong) LocalDatabaseManager *database;

@end

@implementation DIMMessageTable

- (instancetype)init {
    if (self = [super init]) {
        self.caches = [NSMutableDictionary dictionary];
        self.conversations = nil;
        self.database = nil;
    }
    return self;
}

// private
- (LocalDatabaseManager *)database {
    if (!_database) {
        _database = [LocalDatabaseManager sharedInstance];
    }
    return _database;
}

// private
- (ConversationList *)conversations {
    if (!_conversations) {
        _conversations = [self.database loadAllConversations];
    }
    return _conversations;
}

// private
- (void)setCache:(MessageList *)messages forConversation:(id<MKMID>)ID {
    // update cache
    [_caches setObject:messages forKey:ID];
    // add cid
    ConversationList *list = [self conversations];
    if (![list containsObject:ID]) {
        [list addObject:ID];
    }
}

// private
- (void)deleteCacheForConversation:(id<MKMID>)ID {
    // erase cache
    [_caches removeObjectForKey:ID];
    // remove cid
    [_conversations removeObject:ID];
}

// private
- (MessageList *)loadMessages:(id<MKMID>)ID {
    MessageList *messages = [_caches objectForKey:ID];
    if (!messages) {
        messages = [self.database loadMessagesInConversation:ID
                                                       limit:-1
                                                      offset:-1];
        [self setCache:messages forConversation:ID];
    }
    return messages;
}

#pragma mark conversations

- (NSInteger)numberOfConversations {
    return [self.conversations count];
}

- (id<MKMID>)conversationAtIndex:(NSInteger)index {
    return [self.conversations objectAtIndex:index];
}

- (BOOL)removeConversationAtIndex:(NSInteger)index {
    id<MKMID> ID = [self conversationAtIndex:index];
    NSAssert(ID, @"conversation not exists: index=%ld", index);
    return [self removeConversation:ID];
}

- (BOOL)removeConversation:(id<MKMID>)chatBox {
    if ([self.database deleteConversation:chatBox]) {
        [self deleteCacheForConversation:chatBox];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark messages

- (NSInteger)numberOfMessagesInConversation:(id<MKMID>)chatBox {
    MessageList *messages = [self loadMessages:chatBox];
    return [messages count];
}

- (NSInteger)numberOfUnreadMessagesInConversation:(id<MKMID>)chatBox {
    return [self.database getUnreadMessageCount:chatBox];
}

- (BOOL)clearUnreadMessagesInConversation:(id<MKMID>)chatBox {
    return [self.database markMessageRead:chatBox];
}

- (id<DKDInstantMessage>)lastMessageInConversation:(id<MKMID>)chatBox {
    MessageList *messages = [self loadMessages:chatBox];
    if ([messages count] == 0) {
        return nil;
    }
    return [messages objectAtIndex:0];
}

- (id<DKDInstantMessage>)lastReceivedMessageForUser:(id<MKMID>)user {
    // TODO:
    return nil;
}

- (id<DKDInstantMessage>)conversation:(id<MKMID>)chatBox messageAtIndex:(NSInteger)index {
    MessageList *messages = [self loadMessages:chatBox];
    return [messages objectAtIndex:index];
}

- (BOOL)conversation:(id<MKMID>)chatBox insertMessage:(id<DKDInstantMessage>)iMsg {
    if ([self.database addMessage:iMsg toConversation:chatBox]) {
        MessageList *messages = [self loadMessages:chatBox];
        NSAssert(messages, @"messages should not be nil here");
        [messages addObject:iMsg];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)conversation:(id<MKMID>)chatBox removeMessage:(id<DKDInstantMessage>)iMsg {
    MessageList *messages = [self loadMessages:chatBox];
    NSInteger pos = [messages indexOfObject:iMsg];
    if (pos == NSNotFound) {
        return NO;
    }
    [messages removeObjectAtIndex:pos];
    // TODO: remove from database!
    return YES;
}

- (BOOL)conversation:(id<MKMID>)chatBox withdrawMessage:(id<DKDInstantMessage>)iMsg {
    // TODO: mark 'withdraw'
    return NO;
}

- (BOOL)conversation:(id<MKMID>)chatBox saveReceipt:(id<DKDInstantMessage>)iMsg {
    // TODO: add traces
    return NO;
}

#pragma mark -

- (NSArray<id<MKMID>> *)allConversations {
    return [self conversations];
}

- (NSArray<id<DKDInstantMessage>> *)messagesInConversation:(id<MKMID>)ID {
    return [self loadMessages:ID];
}

- (BOOL)clearConversation:(id<MKMID>)ID {
    if ([self.database clearConversation:ID]) {
        [self deleteCacheForConversation:ID];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)markConversationMessageRead:(id<MKMID>)chatBox {
    return [self.database markMessageRead:chatBox];
}

@end
