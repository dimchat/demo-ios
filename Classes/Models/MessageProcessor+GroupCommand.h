//
//  MessageProcessor+GroupCommand.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/10.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "MessageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSString *kNotificationName_GroupMembersUpdated;

@interface MessageProcessor (GroupCommand)

- (BOOL)processGroupCommand:(DIMMessageContent *)content commander:(const DIMID *)sender;

@end

NS_ASSUME_NONNULL_END
