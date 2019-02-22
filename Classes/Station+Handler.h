//
//  Station+Handler.h
//  DIM
//
//  Created by Albert Moky on 2019/2/17.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Station.h"

NS_ASSUME_NONNULL_BEGIN

@interface Station (Handler)

- (void)sendContent:(DIMMessageContent *)content to:(DIMID *)receiver;
- (void)sendMessage:(DIMInstantMessage *)msg;

// pack and send command to station
- (void)sendCommand:(DIMCommand *)cmd;

@end

@interface Station (Command)

- (void)login:(DIMUser *)user;

- (void)handshakeWithUser:(const DIMUser *)user;

- (void)postProfile:(DIMProfile *)profile meta:(nullable DIMMeta *)meta;

- (void)queryMetaForID:(const DIMID *)ID;
- (void)queryProfileForID:(const DIMID *)ID;

- (void)queryOnlineUsers;
- (void)searchUsersWithKeywords:(const NSString *)keywords;

@end

NS_ASSUME_NONNULL_END
