//
//  Facebook+Register.m
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Client.h"

#import "Facebook+Register.h"

static inline NSString *base_directory(DIMID *ID) {
    // base directory ("Documents/.mkm/{address}")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    return [dir stringByAppendingPathComponent:(NSString *)ID.address];
}

/**
 Get group members filepath in Documents Directory
 
 @param groupID - group ID
 @return "Documents/.mkm/{address}/members.plist"
 */
static inline NSString *members_filepath(DIMID *groupID, BOOL autoCreate) {
    // base directory ("Documents/.mkm/{address}")
    NSString *dir = base_directory(groupID);
    // check base directory exists
    if (autoCreate && !file_exists(dir)) {
        // make sure directory exists
        make_dirs(dir);
    }
    return [dir stringByAppendingPathComponent:@"members.plist"];
}

/**
 Get group members filepath in Documents Directory
 
 @return "Documents/.dim/users.plist"
 */
static inline NSString *users_filepath(BOOL autoCreate) {
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".dim"];
    // check base directory exists
    if (autoCreate && !file_exists(dir)) {
        // make sure directory exists
        make_dirs(dir);
    }
    return [dir stringByAppendingPathComponent:@"users.plist"];
}

#pragma mark -

@implementation Facebook (Register)

- (BOOL)saveMeta:(DIMMeta *)meta
      privateKey:(DIMPrivateKey *)SK
           forID:(DIMID *)ID {
    
    NSArray *array = [self scanUserIDList];
    if ([array containsObject:ID]) {
        NSLog(@"User ID already exists: %@", ID);
        return NO;
    }
    
    // 1. check & save meta
    if ([self saveMeta:meta forID:ID]) {
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
    
    // save ("Documents/.dim/users.plist")
    NSString *path = users_filepath(YES);
    NSLog(@"saving new user ID: %@", ID);
    return [users writeToFile:path atomically:YES];
}

- (NSArray<DIMID *> *)scanUserIDList {
    NSMutableArray<DIMID *> *users = nil;
    
    // load from ("Documents/.dim/users.plist")
    NSString *path = users_filepath(NO);
    NSArray *array = [NSArray arrayWithContentsOfFile:path];
    users = [[NSMutableArray alloc] initWithCapacity:[array count]];
    DIMID *ID;
    for (NSString *item in array) {
        ID = DIMIDWithString(item);
        if ([ID isValid]) {
            [users addObject:ID];
        } else {
            NSAssert(false, @"invalid user ID: %@", item);
        }
    }
    NSLog(@"loaded %ld user(s) from %@", users.count, path);
    
    return users;
}

- (BOOL)saveUserIDList:(NSArray<DIMID *> *)users
         withCurrentID:(nullable DIMID *)curr {
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
    // save to ("Documents/.dim/users.plist")
    NSString *path = users_filepath(NO);
    NSLog(@"saving %ld user(s) to %@", users.count, path);
    return [users writeToFile:path atomically:YES];
}

- (BOOL)saveUserList:(NSArray<DIMLocalUser *> *)users
     withCurrentUser:(DIMLocalUser *)curr {
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:users.count];
    for (DIMLocalUser *user in users) {
        [list addObject:user.ID];
    }
    return [self saveUserIDList:list withCurrentID:curr.ID];
}

- (BOOL)removeUser:(DIMLocalUser *)user {
    NSMutableArray<DIMID *> *users = (NSMutableArray *)[self scanUserIDList];
    if ([users containsObject:user.ID]) {
        [users removeObject:user.ID];
        return [self saveUserIDList:users withCurrentID:nil];
    } else {
        NSLog(@"user not exists: %@", user);
        return NO;
    }
}

- (BOOL)saveMembers:(NSArray<DIMID *> *)list
        withGroupID:(DIMID *)grp {
    NSString *path = members_filepath(grp, YES);
    if ([list writeToFile:path atomically:YES]) {
        NSLog(@"members %@ of %@ saved to %@", list, grp, path);
        return YES;
    } else {
        NSAssert(false, @"failed to save members for group: %@, %@", grp, list);
        return NO;
    }
}

- (NSArray<DIMID *> *)loadMembersWithGroupID:(DIMID *)grp {
    NSString *path = members_filepath(grp, NO);
    NSArray *list = [NSArray arrayWithContentsOfFile:path];
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:list.count];
    DIMID *ID;
    for (NSString *item in list) {
        ID = DIMIDWithString(item);
        [mArray addObject:ID];
    }
    return mArray;
}

@end
