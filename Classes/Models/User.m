//
//  User.m
//  DIM
//
//  Created by Albert Moky on 2019/2/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "User.h"

@implementation User

+ (instancetype)userWithConfigFile:(NSString *)config {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:config];
    
    if (!dict) {
        NSLog(@"failed to load: %@", config);
        return nil;
    }
    
    DIMID *ID = [DIMID IDWithID:[dict objectForKey:@"ID"]];
    DIMMeta *meta = [DIMMeta metaWithMeta:[dict objectForKey:@"meta"]];
    [[DIMBarrack sharedInstance] saveMeta:meta forEntityID:ID];
    
    DIMPrivateKey *SK = [DIMPrivateKey keyWithKey:[dict objectForKey:@"privateKey"]];
    DIMPublicKey *PK = [SK publicKey];
    [SK saveKeyWithIdentifier:ID.address];
    
    User *user = [[User alloc] initWithID:ID publicKey:PK];
    user.privateKey = SK;
    
    // profile
    DIMAccountProfile *profile = [dict objectForKey:@"profile"];
    profile = [DIMAccountProfile profileWithProfile:profile];
    if (profile) {
        user.name = profile.name;
    }
    
    return user;
}

@end
