//
//  MessageDatabase.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

// Burn After Reading
#define MAX_MESSAGES_SAVED_COUNT 100

@interface MessageDatabase : DIMConversationDatabase

+ (instancetype)sharedInstance;

- (NSInteger)numberOfConversations;

- (id<MKMID>)conversationAtIndex:(NSInteger)index;

// remove messages file
- (BOOL)removeConversationAtIndex:(NSInteger)index;
- (BOOL)removeConversation:(id<MKMID>)chatBox;

// clear messages records, but keep the empty file
- (BOOL)clearConversationAtIndex:(NSInteger)index;
- (BOOL)clearConversation:(id<MKMID>)chatBox;

@end

NS_ASSUME_NONNULL_END
