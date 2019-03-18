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

- (BOOL)saveMeta:(const DIMMeta *)meta
      privateKey:(const DIMPrivateKey *)SK
           forID:(const DIMID *)ID {
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    
    NSArray *array = [self scanUserIDList];
    if ([array containsObject:ID]) {
        NSLog(@"User ID already exists: %@", ID);
        return NO;
    }
    
    // 1. check & save meta
    if ([barrack saveMeta:meta forEntityID:ID]) {
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
    
    // save ("Documents/.mkm/users.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    make_dirs(dir);
    NSString *path = [dir stringByAppendingPathComponent:@"users.plist"];
    NSLog(@"saving new user ID: %@", ID);
    return [users writeToFile:path atomically:YES];
}

- (NSArray<const DIMID *> *)scanUserIDList {
    NSMutableArray<const DIMID *> *users = nil;
    // load from ("Documents/.mkm/users.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    NSString *path = [dir stringByAppendingPathComponent:@"users.plist"];
    NSArray *array = [NSArray arrayWithContentsOfFile:path];
    users = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSString *item in array) {
        [users addObject:[DIMID IDWithID:item]];
    }
    NSLog(@"loaded %ld user(s) from %@", users.count, path);
    return users;
}

- (BOOL)saveUserIDList:(const NSArray<const MKMID *> *)users
         withCurrentID:(nullable const MKMID *)curr {
    if (users.count == 0) {
        return NO;
    }
    if (curr && [users containsObject:curr]) {
        // exchange the current user to the first
        NSUInteger index = [users indexOfObject:curr];
        if (index > 0) {
            NSMutableArray *mArray = [users mutableCopy];
            [mArray exchangeObjectAtIndex:index withObjectAtIndex:0];
            users = mArray;
        }
    }
    // save to ("Documents/.mkm/users.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    NSString *path = [dir stringByAppendingPathComponent:@"users.plist"];
    NSLog(@"saving %ld user(s) to %@", users.count, path);
    return [users writeToFile:path atomically:YES];
}

- (BOOL)saveUserList:(const NSArray<const MKMUser *> *)users
     withCurrentUser:(const MKMUser *)curr {
    users = [users copy];
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:users.count];
    for (DIMUser *user in users) {
        [list addObject:user.ID];
    }
    return [self saveUserIDList:list withCurrentID:curr.ID];
}

- (BOOL)removeUser:(const DIMUser *)user {
    NSMutableArray<const DIMID *> *users = (NSMutableArray *)[self scanUserIDList];
    if ([users containsObject:user.ID]) {
        [users removeObject:user.ID];
        return [self saveUserIDList:users withCurrentID:nil];
    } else {
        NSLog(@"user not exists: %@", user);
        return NO;
    }
}

- (BOOL)saveProfile:(const DIMProfile *)profile forEntityID:(const DIMID *)ID {
    if (![profile.ID isEqual:ID]) {
        NSAssert(false, @"profile error: %@", profile);
        return NO;
    }
    // update memory cache
    [self setProfile:profile forID:ID];
    
    // save ("Documents/.mkm/{address}/profile.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:(NSString *)ID.address];
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

- (BOOL)saveMembers:(const NSArray<const MKMID *> *)list
        withGroupID:(const MKMID *)grp {
    // save ("Documents/.mkm/{address}/members.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:(NSString *)grp.address];
    make_dirs(dir);
    NSString *path = [dir stringByAppendingPathComponent:@"members.plist"];
    if ([list writeToFile:path atomically:YES]) {
        NSLog(@"members %@ of %@ has been saved to %@", list, grp, path);
        return YES;
    } else {
        NSAssert(false, @"failed to save members for group: %@, %@", grp, list);
        return NO;
    }
}

- (NSArray<const DIMID *> *)loadMembersWithGroupID:(const MKMID *)grp {
    // save ("Documents/.mkm/{address}/members.plist")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:(NSString *)grp.address];
    make_dirs(dir);
    NSString *path = [dir stringByAppendingPathComponent:@"members.plist"];
    NSArray *list = [NSArray arrayWithContentsOfFile:path];
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:list.count];
    DIMID *ID;
    for (NSString *item in list) {
        ID = [DIMID IDWithID:item];
        [mArray addObject:ID];
    }
    return mArray;
}

@end
