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
//  DIMMessageTable.h
//  DIMP
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMStorage.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DIMMessageTable <NSObject>

/**
 *  Get how many chat boxes
 *
 * @return conversations count
 */
- (NSInteger)numberOfConversations;

/**
 *  Get chat box info
 *
 * @param index - sorted index
 * @return conversation ID
 */
- (id<MKMID>)conversationAtIndex:(NSInteger)index;

/**
 *  Remove one chat box
 *
 * @param index - chat box index
 * @return true on row(s) affected
 */
- (BOOL)removeConversationAtIndex:(NSInteger)index;

/**
 *  Remove the chat box
 *
 * @param chatBox - conversation ID
 * @return true on row(s) affected
 */
- (BOOL)removeConversation:(id<MKMID>)chatBox;

#pragma mark messages

/**
 *  Get message count in this conversation for an entity
 *
 * @param chatBox - conversation ID
 * @return total count
 */
- (NSInteger)numberOfMessagesInConversation:(id<MKMID>)chatBox;

/**
 *  Get unread message count in this conversation for an entity
 *
 * @param chatBox - conversation ID
 * @return unread count
 */
- (NSInteger)numberOfUnreadMessagesInConversation:(id<MKMID>)chatBox;

/**
 *  Clear unread flag in this conversation for an entity
 *
 * @param chatBox - conversation ID
 * @return true on row(s) affected
 */
- (BOOL)clearUnreadMessagesInConversation:(id<MKMID>)chatBox;

/**
 *  Get last message of this conversation
 *
 * @param chatBox - conversation ID
 * @return instant message
 */
- (id<DKDInstantMessage>)lastMessageInConversation:(id<MKMID>)chatBox;

/**
 *  Get last received message from all conversations
 *
 * @param user - current user ID
 * @return instant message
 */
- (id<DKDInstantMessage>)lastReceivedMessageForUser:(id<MKMID>)user;

/**
 *  Get message at index of this conversation
 *
 * @param index - start from 0, latest first
 * @param chatBox - conversation ID
 * @return instant message
 */
- (id<DKDInstantMessage>)conversation:(id<MKMID>)chatBox messageAtIndex:(NSInteger)index;

/**
 *  Save the new message to local storage
 *
 * @param iMsg - instant message
 * @param chatBox - conversation ID
 * @return true on success
 */
- (BOOL)conversation:(id<MKMID>)chatBox insertMessage:(id<DKDInstantMessage>)iMsg;

/**
 *  Delete the message
 *
 * @param iMsg - instant message
 * @param chatBox - conversation ID
 * @return true on row(s) affected
 */
- (BOOL)conversation:(id<MKMID>)chatBox removeMessage:(id<DKDInstantMessage>)iMsg;

/**
 *  Try to withdraw the message, maybe won't success
 *
 * @param iMsg - instant message
 * @param chatBox - conversation ID
 * @return true on success
 */
- (BOOL)conversation:(id<MKMID>)chatBox withdrawMessage:(id<DKDInstantMessage>)iMsg;

/**
 *  Update message state with receipt
 *
 * @param iMsg - message with receipt content
 * @param chatBox - conversation ID
 * @return true while target message found
 */
- (BOOL)conversation:(id<MKMID>)chatBox saveReceipt:(id<DKDInstantMessage>)iMsg;

@end

@interface DIMMessageTable : DIMStorage <DIMMessageTable>

- (NSArray<id<MKMID>> *)allConversations;

- (NSArray<id<DKDInstantMessage>> *)messagesInConversation:(id<MKMID>)ID;

- (BOOL)clearConversation:(id<MKMID>)ID;

- (BOOL)markConversationMessageRead:(id<MKMID>)chatBox;

@end

NS_ASSUME_NONNULL_END
