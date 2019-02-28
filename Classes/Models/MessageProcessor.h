//
//  MessageProcessor.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/15.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

NSString *NSStringFromDate(const NSDate *date);

@interface MessageProcessor : NSObject <DIMConversationDataSource,
                                        DIMConversationDelegate>

+ (instancetype)sharedInstance;

- (NSInteger)numberOfConversations;

- (DIMConversation *)conversationAtIndex:(NSInteger)index;

- (BOOL)reloadData;

@end

NS_ASSUME_NONNULL_END
