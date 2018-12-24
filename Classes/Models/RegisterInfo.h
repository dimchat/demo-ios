//
//  RegisterInfo.h
//  DIMClient
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface RegisterInfo : DIMDictionary

@property (strong, nonatomic) NSString *nickname;
@property (strong, nonatomic) NSString *username;

@property (strong, nonatomic) DIMPrivateKey *SK;
@property (strong, nonatomic) DIMPublicKey *PK;

@property (strong, nonatomic) DIMMeta *meta;
@property (strong, nonatomic) DIMID *ID;

@property (strong, nonatomic) DIMUser *user;

@end

NS_ASSUME_NONNULL_END
