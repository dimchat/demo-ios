//
//  Facebook+Register.m
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSDictionary+Binary.h"

#import "Client.h"

#import "Facebook+Register.h"

@implementation Facebook (Register)

- (BOOL)saveRegisterInfo:(DIMRegisterInfo *)info {
    NSLog(@"saving register info: %@", info);
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    
    // ID
    DIMID *ID = info.ID;
    if (!ID) {
        ID = info.user.ID;
    }
    NSArray *array = [self scanUserIDList];
    if ([array containsObject:ID]) {
        NSLog(@"User ID already exists");
        return NO;
    }
    
    // meta
    DIMMeta *meta = info.meta;
    
    // 1. check & save meta
    if ([meta matchID:ID]) {
        if ([barrack saveMeta:meta forEntityID:ID]) {
            NSLog(@"meta saved: %@", meta);
        } else {
            NSAssert(false, @"save meta failed");
            return NO;
        }
    } else {
        NSAssert(false, @"meta not match ID: %@, %@", ID, meta);
        return NO;
    }
    
    // public key
    DIMPublicKey *PK = info.publicKey;
    if (!PK) {
        PK = meta.key;
    }
    
    // private key
    DIMPrivateKey *SK = info.privateKey;
    if (!SK) {
        SK = info.user.privateKey;
    }
    
    // 2. check & save private key
    if ([PK isMatch:SK]) {
        if ([SK saveKeyWithIdentifier:ID.address]) {
            NSLog(@"private key saved: %@", SK);
        } else {
            NSAssert(false, @"save private key failed");
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
    
    // save ("Documents/.mkm/users.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    make_dirs(dir);
    NSString *path = [dir stringByAppendingPathComponent:@"users.plist"];
    NSLog(@"saving new user ID: %@", ID);
    return [users writeToFile:path atomically:YES];
}

- (NSArray<DIMID *> *)scanUserIDList {
    NSMutableArray<DIMID *> *users = nil;
    // load ("Documents/.mkm/users.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    NSString *path = [dir stringByAppendingPathComponent:@"users.plist"];
    NSArray *array = [NSArray arrayWithContentsOfFile:path];
    users = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSString *item in array) {
        [users addObject:[DIMID IDWithID:item]];
    }
    return users;
}

- (BOOL)saveProfile:(DIMProfile *)profile forID:(DIMID *)ID {
    NSAssert([profile.ID isEqual:ID], @"profile error: %@", profile);
    // save ("Documents/.mkm/{address}/profile.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:ID.address];
    make_dirs(dir);
    NSString *path = [dir stringByAppendingPathComponent:@"profile.plist"];
    if ([profile writeToBinaryFile:path]) {
        NSLog(@"profile %@ of %@ has been saved to %@", profile, ID, path);
        return YES;
    } else {
        NSAssert(false, @"failed to save profile for ID: %@, %@", ID, profile);
        return NO;
    }
}

@end
