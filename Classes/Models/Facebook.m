//
//  Facebook.m
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSDate+Timestamp.h"
#import "NSDictionary+Binary.h"
#import "NSNotificationCenter+Extension.h"

#import "MKMImmortals.h"

#import "DIMProfile+Extension.h"

#import "User.h"

#import "Client.h"
#import "Facebook+Profile.h"
#import "Facebook+Register.h"

#import "Facebook.h"

NSString * const kNotificationName_ContactsUpdated = @"ContactsUpdated";

@interface Facebook () {
    
    MKMImmortals *_immortals;
}

@end

@implementation Facebook

SingletonImplementations(Facebook, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        // immortal accounts
        _immortals = [[MKMImmortals alloc] init];
        
        // delegates
        DIMFacebook *barrack = [DIMFacebook sharedInstance];
        barrack.database   = self;
        
        // scan users
        NSArray *users = [self allUsers];
#if DEBUG && 0
        NSMutableArray *mArray;
        if (users.count > 0) {
            mArray = [users mutableCopy];
        } else {
            mArray = [[NSMutableArray alloc] initWithCapacity:2];
        }
        [mArray addObject:DIMIDWithString(MKM_IMMORTAL_HULK_ID)];
        [mArray addObject:DIMIDWithString(MKM_MONKEY_KING_ID)];
        users = mArray;
#endif
        // add users
        Client *client = [Client sharedInstance];
        DIMLocalUser *user;
        for (DIMID *ID in users) {
            NSLog(@"[client] add user: %@", ID);
            user = DIMUserWithID(ID);
            [client addUser:user];
        }
        
        [NSNotificationCenter addObserver:self
                                 selector:@selector(onProfileUpdated:)
                                     name:kNotificationName_ProfileUpdated
                                   object:client];
    }
    return self;
}

- (void)onProfileUpdated:(NSNotification *)notification {
    if (![notification.name isEqual:kNotificationName_ProfileUpdated]) {
        return ;
    }
    DIMProfileCommand *cmd = (DIMProfileCommand *)notification.userInfo;
    DIMProfile *profile = cmd.profile;
    NSAssert([profile.ID isEqual:cmd.ID], @"profile command error: %@", cmd);
    [profile removeObjectForKey:@"lastTime"];
    
    // check avatar
    NSString *avatar = profile.avatar;
    if (avatar) {
//        // if old avatar exists, remove it
//        DIMID *ID = profile.ID;
//        DIMProfile *old = [self profileForID:ID];
//        NSString *ext = [old.avatar pathExtension];
//        if (ext/* && ![avatar isEqualToString:old.avatar]*/) {
//            // Cache directory: "Documents/.mkm/{address}/avatar.png"
//            NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/avatar.%@", document_directory(), ID.address, ext];
//            NSFileManager *fm = [NSFileManager defaultManager];
//            if ([fm fileExistsAtPath:path]) {
//                NSError *error = nil;
//                if (![fm removeItemAtPath:path error:&error]) {
//                    NSLog(@"failed to remove old avatar: %@", error);
//                } else {
//                    NSLog(@"old avatar removed: %@", path);
//                }
//            }
//        }
    }
    
    // update profile
    [[DIMFacebook sharedInstance] saveProfile:profile];
}

- (void)addStation:(DIMID *)stationID provider:(DIMServiceProvider *)sp {
//    NSMutableArray *stations = [_contactsTable objectForKey:sp.ID.address];
//    if (stations) {
//        if ([stations containsObject:stationID]) {
//            NSLog(@"station %@ already exists, provider: %@", stationID, sp.ID);
//            return ;
//        } else {
//            [stations addObject:stationID];
//        }
//    } else {
//        stations = [[NSMutableArray alloc] initWithCapacity:1];
//        [stations addObject:stationID];
//        [_contactsTable setObject:stations forKey:sp.ID.address];
//    }
}

#pragma mark - DIMEntityDataSource

- (nullable DIMMeta *)metaForID:(DIMID *)ID {
    DIMMeta *meta;
    // try immortals first
    if (MKMNetwork_IsPerson(ID.type)) {
        meta = [_immortals metaForID:ID];
        if (meta) {
            return meta;
        }
    }
    
    // get from local storage
    meta = [super metaForID:ID];
    if (meta) {
        return meta;
    }
    
    // query from DIM network
    [[Client sharedInstance] queryMetaForID:ID];
    NSLog(@"querying meta from DIM network for ID: %@", ID);
    
    return meta;
}

- (nullable __kindof DIMProfile *)profileForID:(DIMID *)ID {
    DIMProfile *profile;
    // try immortals first
    if (MKMNetwork_IsPerson(ID.type)) {
        profile = [_immortals profileForID:ID];
        if (profile) {
            return profile;
        }
    }
    
    // get from local storage
    profile = [super profileForID:ID];
    if ([profile objectForKey:@"lastTime"]) {
        return profile;
    }

    // send query for updating from DIM network
    [[Client sharedInstance] queryProfileForID:ID];
    NSLog(@"querying profile from DIM network for ID: %@", ID);
    
    return profile;
}

@end
