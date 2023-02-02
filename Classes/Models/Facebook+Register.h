//
//  Facebook+Register.h
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMFacebook (Register)

- (BOOL)saveMeta:(id<MKMMeta>)meta privateKey:(id<MKMPrivateKey>)SK forID:(id<MKMID>)ID;

- (BOOL)saveUserList:(NSArray<id<DIMUser>> *)users withCurrentUser:(nullable id<DIMUser>)curr;

@end

NS_ASSUME_NONNULL_END
