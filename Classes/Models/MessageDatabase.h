//
//  MessageDatabase.h
//  DIMP
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "DIMConversationDatabase.h"

NS_ASSUME_NONNULL_BEGIN

// Burn After Reading
#define MAX_MESSAGES_SAVED_COUNT 100

@interface MessageDatabase : DIMConversationDatabase

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
