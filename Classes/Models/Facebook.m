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
        DIMUser *user;
        for (DIMID *ID in users) {
            NSLog(@"[client] add user: %@", ID);
            user = DIMUserWithID(ID);
            [client addUser:user];
        }
    }
    return self;
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
    if ([ID isBroadcast]) {
        return nil;
    }
    DIMMeta *meta = [super metaForID:ID];
    if (!meta) {
        if (MKMNetwork_IsPerson(ID.type)) {
            // try immortals
            meta = [_immortals metaForID:ID];
        }
        if (!meta) {
            // query from DIM network
            [[Client sharedInstance] queryMetaForID:ID];
            NSLog(@"querying meta from DIM network for ID: %@", ID);
        }
    }
    return meta;
}

- (nullable __kindof DIMProfile *)profileForID:(DIMID *)ID {
    DIMProfile *profile = [super profileForID:ID];
    NSAssert(profile, @"profile would not be empty here");
    BOOL isEmpty = ![profile objectForKey:@"data"];
    if (isEmpty) {
        if (MKMNetwork_IsPerson(ID.type)) {
            // try immortals
            DIMProfile *tai = [_immortals profileForID:ID];
            if (tai) {
                profile = tai;
            }
        }
    }
    // check last update time
    BOOL needsUpdate = isEmpty;
    NSNumber *timestamp = [profile objectForKey:@"lastTime"];
    if (timestamp) {
        NSDate *lastTime = NSDateFromNumber(timestamp);
        NSTimeInterval ti = [lastTime timeIntervalSinceNow];
        needsUpdate = fabs(ti) > 3600;
    } else {
        // first loaded, set last update time
        NSDate *now = [[NSDate alloc] init];
        [profile setObject:NSNumberFromDate(now) forKey:@"lastTime"];
    }
    if (needsUpdate) {
        // not found or expired? send query for updating from DIM network
        [[Client sharedInstance] queryProfileForID:ID];
        NSLog(@"querying profile for ID: %@", ID);
    }
    return profile;
}

- (BOOL)saveProfile:(DIMProfile *)profile {
    // TODO: [discuss]
    //       should the expired time be calculated from the launch time?
    
    // erase last update time
    //[profile removeObjectForKey:@"lastTime"];
    
    // set last update time
    NSDate *now = [[NSDate alloc] init];
    [profile setObject:NSNumberFromDate(now) forKey:@"lastTime"];
    
    return [super saveProfile:profile];
}

#pragma mark - MKMGroupDataSource

- (nullable NSArray<MKMID *> *)membersOfGroup:(MKMID *)group {
    NSArray<DIMID *> *members = [super membersOfGroup:group];
    if ([members count] == 0) {
        DIMGroup *grp = DIMGroupWithID(group);
        Client *client = [Client sharedInstance];
        // query from DIM network
        DIMQueryGroupCommand *query = [[DIMQueryGroupCommand alloc] initWithGroup:group];
        // query assistant
        NSArray<DIMID *> *assistants = grp.assistants;
        for (DIMID *ass in assistants) {
            [client sendContent:query to:ass];
        }
    }
    return members;
}

@end
