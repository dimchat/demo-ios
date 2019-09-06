//
//  Facebook+Register.h
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Facebook.h"

NS_ASSUME_NONNULL_BEGIN

@interface Facebook (Register)

- (BOOL)saveMeta:(DIMMeta *)meta privateKey:(DIMPrivateKey *)SK forID:(DIMID *)ID;

- (BOOL)saveUserList:(NSArray<DIMLocalUser *> *)users withCurrentUser:(nullable DIMLocalUser *)curr;

@end

NS_ASSUME_NONNULL_END
