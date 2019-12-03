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

- (BOOL)saveMeta:(DIMMeta *)meta privateKey:(DIMPrivateKey *)SK forID:(DIMID *)ID;

- (BOOL)saveUserList:(NSArray<DIMUser *> *)users withCurrentUser:(nullable DIMUser *)curr;

@end

NS_ASSUME_NONNULL_END
