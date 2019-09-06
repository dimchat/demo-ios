//
//  Facebook+Register.m
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Client.h"

#import "Facebook+Register.h"

@implementation Facebook (Register)

- (BOOL)saveMeta:(DIMMeta *)meta
      privateKey:(DIMPrivateKey *)SK
           forID:(DIMID *)ID {
    
    NSArray *array = [self allUsers];
    if ([array containsObject:ID]) {
        NSLog(@"User ID already exists: %@", ID);
        return NO;
    }
    
    // 1. check & save meta
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    if ([facebook saveMeta:meta forID:ID]) {
        NSLog(@"meta saved: %@", meta);
    } else {
        NSAssert(false, @"save meta failed: %@, %@", ID, meta);
        return NO;
    }
    
    // 2. check & save private key
    DIMPublicKey *PK = meta.key;
    if ([PK isMatch:SK]) {
        if ([SK saveKeyWithIdentifier:ID.address]) {
            NSLog(@"private key saved: %@", SK);
        } else {
            NSAssert(false, @"save private key failed: %@", ID);
            return NO;
        }
    } else {
        NSAssert(false, @"asymmetric keys not match: %@, %@", PK, SK);
        return NO;
    }
    
    // 3. save user ID to local file
    
    // add current user ID to exists users
    NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:(array.count + 1)];
    [users addObject:ID];
    [users addObjectsFromArray:array];
    
    return [self saveUsers:users];
}

- (BOOL)saveUserList:(NSArray<DIMLocalUser *> *)users
     withCurrentUser:(DIMLocalUser *)curr {
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:users.count];
    [list addObject:curr.ID];
    for (DIMLocalUser *user in users) {
        if ([list containsObject:user.ID]) {
            // ignore
        } else {
            [list addObject:user.ID];
        }
    }
    return [self saveUsers:list];
}

@end
