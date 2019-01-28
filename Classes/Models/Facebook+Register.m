//
//  Facebook+Register.m
//  DIM
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Client+Ext.h"

#import "Facebook+Register.h"

@implementation Facebook (Register)

- (BOOL)saveRegisterInfo:(MKMRegisterInfo *)info {
    NSLog(@"saving register info: %@", info);
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    
    DIMID *ID = info.ID;
    if (!ID) {
        ID = info.user.ID;
    }
    NSArray *array = [self scanUserIDList];
    NSMutableArray *users = [[NSMutableArray alloc] initWithCapacity:(array.count + 1)];
    [users addObjectsFromArray:array];
    if ([users containsObject:ID]) {
        NSLog(@"User ID already exists");
        return NO;
    }
    
    // save meta
    DIMMeta *meta = info.meta;
    if ([meta matchID:ID]) {
        if ([barrack saveMeta:meta forEntityID:ID]) {
            NSLog(@"meta saved: %@", meta);
        } else {
            NSAssert(false, @"save meta filed");
            return NO;
        }
    } else {
        NSAssert(false, @"meta not match ID: %@, %@", ID, meta);
        return NO;
    }
    
    // save private key
    DIMPrivateKey *SK = info.privateKey;
    if (!SK) {
        SK = info.user.privateKey;
    }
    [SK saveKeyWithIdentifier:ID.address];
    NSLog(@"private key saved: %@", SK);
    
    // add current user ID to exists users
    [users addObject:ID];
    // save ("Documents/.mkm/users.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    make_dirs(dir);
    NSString *path = [dir stringByAppendingPathComponent:@"users.plist"];
    NSLog(@"saving new user ID: %@", ID);
    return [users writeToFile:path atomically:YES];
}

- (NSArray<MKMID *> *)scanUserIDList {
    NSMutableArray<MKMID *> *users = nil;
    // load ("Documents/.mkm/users.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    NSString *path = [dir stringByAppendingPathComponent:@"users.plist"];
    NSArray *array = [NSArray arrayWithContentsOfFile:path];
    users = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSString *item in array) {
        [users addObject:[MKMID IDWithID:item]];
    }
    return users;
}

- (BOOL)saveProfile:(MKMProfile *)profile forID:(MKMID *)ID {
    NSLog(@"saving profile: %@ for ID: %@", profile, ID);
    
    // load "Documents/.mkm/{address}/profile.plist"
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:ID.address];
    make_dirs(dir);
    NSString *path = [dir stringByAppendingPathComponent:@"profile.plist"];
    if ([profile writeToFile:path atomically:YES]) {
        return YES;
    } else {
        NSAssert(false, @"failed to save profile for ID: %@, %@", ID, profile);
        return NO;
    }
}

@end
