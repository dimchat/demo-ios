//
//  MessageProcessor+Station.h
//  SeChat
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "MessageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MessageProcessor (Station)

- (void)processHandshakeMessageContent:(DIMMessageContent *)content;

- (void)processMetaMessageContent:(DIMMessageContent *)content;
- (void)processProfileMessageContent:(DIMMessageContent *)content;

- (void)processOnlineUsersMessageContent:(DIMMessageContent *)content;
- (void)processSearchUsersMessageContent:(DIMMessageContent *)content;

@end

NS_ASSUME_NONNULL_END
