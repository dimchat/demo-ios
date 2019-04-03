//
//  MessageProcessor.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

// Burn After Reading
#define MAX_MESSAGES_SAVED_COUNT 100

@interface MessageProcessor : NSObject <DIMConversationDataSource,
                                        DIMConversationDelegate>

+ (instancetype)sharedInstance;

- (NSInteger)numberOfConversations;

- (DIMConversation *)conversationAtIndex:(NSInteger)index;

// remove messages file
- (BOOL)removeConversationAtIndex:(NSInteger)index;
- (BOOL)removeConversation:(DIMConversation *)chatBox;

// clear messages records, but keep the empty file
- (BOOL)clearConversationAtIndex:(NSInteger)index;
- (BOOL)clearConversation:(DIMConversation *)chatBox;

- (BOOL)reloadData;

@end

@interface MessageProcessor (Send)

/**
 *  Pack and send message (secured + certified) to target station
 *
 *  @param content - message content
 *  @param sender - sender ID
 *  @param receiver - receiver ID
 *  @param callback - callback function
 *  @return NO on data/delegate error
 */
- (BOOL)sendMessageContent:(const DIMMessageContent *)content
                      from:(const DIMID *)sender
                        to:(const DIMID *)receiver
                      time:(nullable const NSDate *)time
                  callback:(nullable DIMTransceiverCallback)callback;

@end

NS_ASSUME_NONNULL_END
