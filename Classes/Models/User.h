//
//  User.h
//  DIM
//
//  Created by Albert Moky on 2019/2/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface User : DIMUser

+ (instancetype)userWithConfigFile:(NSString *)config;

@end

NS_ASSUME_NONNULL_END
