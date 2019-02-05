//
//  Facebook+Register.h
//  DIM
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Facebook.h"

NS_ASSUME_NONNULL_BEGIN

@interface Facebook (Register)

- (BOOL)saveRegisterInfo:(DIMRegisterInfo *)info;

- (NSArray<DIMID *> *)scanUserIDList;

- (BOOL)saveProfile:(DIMProfile *)profile forID:(DIMID *)ID;

@end

NS_ASSUME_NONNULL_END
