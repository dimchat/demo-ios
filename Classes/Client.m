//
//  Client.m
//  DIM
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"

#import "Station.h"
#import "Facebook.h"

#import "Client.h"

@interface Client ()

@property (strong, nonatomic) NSMutableArray<DIMUser *> *users;

@end

@implementation Client

SingletonImplementations(Client, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        _users = [[NSMutableArray alloc] init];
        _currentUser = nil;
    }
    return self;
}

- (NSString *)userAgent {
    return @"DIMP/1.0 (iPad; U; iOS 11.4; zh-CN) DIMCoreKit/1.0 (Terminal, like WeChat) DIM-by-GSP/1.0.1";
}

#pragma mark - Users

- (void)setCurrentUser:(DIMUser *)currentUser {
    if (![_currentUser isEqual:currentUser]) {
        _currentUser = currentUser;
        // add to the list of this client
        if (currentUser && ![_users containsObject:currentUser]) {
            [_users addObject:currentUser];
        }
        
        // update keystore
        [DIMKeyStore sharedInstance].currentUser = currentUser;
    }
}

- (void)addUser:(DIMUser *)user {
    if (user && ![_users containsObject:user]) {
        [_users addObject:user];
    }
    // check current user
    if (!_currentUser) {
        _currentUser = user;
    }
}

- (void)removeUser:(DIMUser *)user {
    if ([_users containsObject:user]) {
        [_users removeObject:user];
    }
    // check current user
    if ([_currentUser isEqual:user]) {
        _currentUser = _users.firstObject;
    }
}

#pragma mark -

- (void)postNotificationName:(NSNotificationName)aName {
    [self postNotificationName:aName object:nil userInfo:nil];
}
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject {
    [self postNotificationName:aName object:anObject userInfo:nil];
}

- (void)postNotificationName:(NSNotificationName)aName
                      object:(nullable id)anObject
                    userInfo:(nullable NSDictionary *)aUserInfo {
    NSNotification *noti = [[NSNotification alloc] initWithName:aName
                                                         object:anObject
                                                       userInfo:aUserInfo];
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc performSelectorOnMainThread:@selector(postNotification:) withObject:noti waitUntilDone:NO];
}

@end

#pragma mark -

NSString *document_directory(void) {
    NSArray *paths;
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask, YES);
    return paths.firstObject;
}

void make_dirs(NSString *dir) {
    // check base directory exists
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir isDirectory:nil]) {
        NSError *error = nil;
        // make sure directory exists
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                       attributes:nil error:&error];
        assert(!error);
    }
}

BOOL file_exists(NSString *path) {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:path];
}
