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
//  DIMConversationDatabase.m
//  DIMP
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMGlobalVariable.h"

#import "DIMMessageTable.h"
#import "DIMConstants.h"

#import "DIMConversationDatabase.h"

@implementation DIMConversationDatabase

OKSingletonImplementations(DIMConversationDatabase, sharedInstance)

- (NSArray<id<MKMID>> *)allConversations {
    return [_messageTable allConversations];
}

- (NSArray<id<DKDInstantMessage>> *)messagesInConversation:(id<MKMID>)chatBox {
    return [_messageTable messagesInConversation:chatBox];
}

-(BOOL)markConversationMessageRead:(id<MKMID>)chatBox{
    BOOL result = [_messageTable markConversationMessageRead:chatBox];
    
    if (result) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:kNotificationName_ConversationUpdated
                          object:self
                        userInfo:@{@"ID": chatBox}];
    }
    
    return result;
}

#pragma mark DIMConversationDataSource

- (NSInteger)numberOfConversations {
    return [_messageTable numberOfConversations];
}

- (id<MKMID>)conversationAtIndex:(NSInteger)index {
    return [_messageTable conversationAtIndex:index];
}

- (BOOL)removeConversationAtIndex:(NSInteger)index {
    return [_messageTable removeConversationAtIndex:index];
}

- (BOOL)removeConversation:(id<MKMID>)chatBox {
    BOOL result = [_messageTable removeConversation:chatBox];
    
    if (result) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:kNotificationName_MessageCleaned object:self
                        userInfo:@{@"ID": chatBox}];
    }
    
    return result;
}

- (BOOL)clearConversation:(id<MKMID>)chatBox {
    return [_messageTable clearConversation:chatBox];
}

#pragma mark DIMConversationDataSource

- (NSInteger)numberOfMessagesInConversation:(id<MKMID>)chatBox {
    return [_messageTable numberOfMessagesInConversation:chatBox];
}

- (NSInteger)numberOfUnreadMessagesInConversation:(id<MKMID>)chatBox {
    return [_messageTable numberOfUnreadMessagesInConversation:chatBox];
}

- (BOOL)clearUnreadMessagesInConversation:(id<MKMID>)chatBox {
    return [_messageTable clearUnreadMessagesInConversation:chatBox];
}

- (id<DKDInstantMessage>)lastMessageInConversation:(id<MKMID>)chatBox {
    return [_messageTable lastMessageInConversation:chatBox];
}

- (id<DKDInstantMessage>)lastReceivedMessageForUser:(id<MKMID>)user {
    return [_messageTable lastReceivedMessageForUser:user];
}

- (id<DKDInstantMessage>)conversation:(id<MKMID>)chatBox messageAtIndex:(NSInteger)index {
    return [_messageTable conversation:chatBox messageAtIndex:index];
}

#pragma mark DIMConversationDelegate

- (BOOL)conversation:(id<MKMID>)chatBox insertMessage:(id<DKDInstantMessage>)iMsg {
    
    BOOL OK = [_messageTable conversation:chatBox insertMessage:iMsg];
    
    if (OK) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        [nc postNotificationName:kNotificationName_ConversationUpdated
                          object:self
                        userInfo:@{@"ID": chatBox}];
        
        [nc postNotificationName:kNotificationName_MessageInserted
                          object:self
                        userInfo:@{@"Conversation": chatBox, @"Message": iMsg}];
    }
    
    return OK;
    
//    NSArray<id<DKDInstantMessage>> *messages;
//    messages = [_messageTable messagesInConversation:chatBox.ID];
//    if (!messages) {
//        messages = [[NSMutableArray alloc] initWithCapacity:1];
//    }
//    [(NSMutableArray *)messages addObject:iMsg];
//
//    // TODO: Burn After Reading
//    return [_messageTable saveMessages:messages conversation:chatBox.ID];
}

- (BOOL)conversation:(id<MKMID>)chatBox removeMessage:(id<DKDInstantMessage>)iMsg {
    return [self conversation:chatBox removeMessage:iMsg];
}

- (BOOL)conversation:(id<MKMID>)chatBox withdrawMessage:(id<DKDInstantMessage>)iMsg {
    return [self conversation:chatBox withdrawMessage:iMsg];
}

- (BOOL)conversation:(id<MKMID>)chatBox saveReceipt:(id<DKDInstantMessage>)iMsg {
    return [self conversation:chatBox saveReceipt:iMsg];
}

@end
