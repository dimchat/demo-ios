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
        
        // contacts list of each user
        _contactsTable = [[NSMutableDictionary alloc] init];
        
        // profile cache
        _profileTable = [[NSMutableDictionary alloc] init];
        
        // delegates
        DIMBarrack *barrack = [DIMFacebook sharedInstance];
        barrack.entityDataSource   = self;
        barrack.userDataSource     = self;
        barrack.groupDataSource    = self;
        
        // scan users
        NSArray *users = [self scanUserIDList];
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
    [self saveProfile:profile];
}

- (nullable DIMID *)IDWithAddress:(DIMAddress *)address {
    DIMID *ID;
    NSArray *tables = _contactsTable.allValues;
    for (NSArray *list in tables) {
        for (id item in list) {
            ID = DIMIDWithString(item);
            if ([ID.address isEqual:address]) {
                return ID;
            }
        }
    }
    ID = nil;
    
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    
    NSString *path = [NSString stringWithFormat:@"%@/meta.plist", address];
    path = [dir stringByAppendingPathComponent:path];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        NSString *seed = [dict objectForKey:@"seed"];
        NSString *idstr = [NSString stringWithFormat:@"%@@%@", seed, address];
        ID = DIMIDWithString(idstr);
        NSLog(@"Address -> number: %@, ID: %@", search_number(ID.number), ID);
    } else {
        NSLog(@"meta file not exists: %@", path);
    }
    
    return ID;
}

- (void)addStation:(DIMID *)stationID provider:(DIMServiceProvider *)sp {
    NSMutableArray *stations = [_contactsTable objectForKey:sp.ID.address];
    if (stations) {
        if ([stations containsObject:stationID]) {
            NSLog(@"station %@ already exists, provider: %@", stationID, sp.ID);
            return ;
        } else {
            [stations addObject:stationID];
        }
    } else {
        stations = [[NSMutableArray alloc] initWithCapacity:1];
        [stations addObject:stationID];
        [_contactsTable setObject:stations forKey:sp.ID.address];
    }
}

// {document_directory}/.mkm/{address}/contacts.plist
- (ContactTable *)reloadContactsWithUser:(DIMID *)user {
    NSString *dir = document_directory();
    NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/contacts.plist", dir, user.address];
    
    NSMutableArray<DIMID *> *contacts = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        contacts = [[NSMutableArray alloc] initWithContentsOfFile:path];
    }
    
    if (contacts) {
        NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:contacts.count];
        DIMID *ID;
        for (NSString *item in contacts) {
            ID = DIMIDWithString(item);
            [mArray addObject:ID];
        }
        contacts = mArray;
        [_contactsTable setObject:contacts forKey:user.address];
    } else {
        [_contactsTable removeObjectForKey:user.address];
        contacts = [[NSMutableArray alloc] init];
    }
    return contacts;
}

#pragma mark - MKMEntityDataSource

- (BOOL)saveMeta:(DIMMeta *)meta forID:(DIMID *)ID {
    if (![meta matchID:ID]) {
        NSAssert(false, @"meta not match ID: %@, %@", ID, meta);
        return NO;
    }
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:ID.address];
    if (!file_exists(dir)) {
        // make sure directory exists
        make_dirs(dir);
    }
    NSString *path = [dir stringByAppendingPathComponent:@"meta.plist"];
    if (file_exists(path)) {
        // no need to update meta file
        return YES;
    }
    if ([meta writeToBinaryFile:path]) {
        NSLog(@"meta %@ of %@ has been saved to %@", meta, ID, path);
        return YES;
    } else {
        NSAssert(false, @"failed to save meta for ID: %@, %@", ID, meta);
        return NO;
    }
}

- (nullable DIMMeta *)metaForID:(DIMID *)ID {
    DIMMeta *meta = nil;
    
    if (MKMNetwork_IsPerson(ID.type)) {
        meta = [_immortals metaForID:ID];
        if (meta) {
            return meta;
        }
    }
    
    // load meta from database
    DIMFacebook *barrack = [DIMFacebook sharedInstance];
    meta = [barrack loadMetaForID:ID];
    
    if (!meta) {
        // query from DIM network
        Client *client = [Client sharedInstance];
        [client queryMetaForID:ID];
        NSLog(@"querying meta for ID: %@", ID);
    }
    
    return meta;
}

- (nullable __kindof DIMProfile *)profileForID:(DIMID *)ID {
    // try from profile cache
    DIMProfile *profile = [_profileTable objectForKey:ID.address];;
    if (profile) {
        // check cache expires
        NSNumber *timestamp = [profile objectForKey:@"lastTime"];
        if (timestamp != nil) {
            NSDate *lastTime = NSDateFromNumber(timestamp);
            NSTimeInterval ti = [lastTime timeIntervalSinceNow];
            if (fabs(ti) > 3600) {
                NSLog(@"profile expired: %@", lastTime);
                [_profileTable removeObjectForKey:ID.address];
            }
        } else {
            NSDate *now = [[NSDate alloc] init];
            [profile setObject:NSNumberFromDate(now) forKey:@"lastTime"];
        }
        return profile;
    }
    
    do {
        // send query for updating from network
        [[Client sharedInstance] queryProfileForID:ID];
        
        // try from "Documents/.mkm/{address}/profile.plist"
        profile = [self loadProfileForID:ID];
        if (profile) {
            break;
        }
        
        // try immortals
        if (MKMNetwork_IsPerson(ID.type)) {
            profile = [_immortals profileForID:ID];
            if (profile) {
                break;
            }
        }
        
        // place an empty profile for cache
        profile = [[DIMProfile alloc] initWithID:ID];
        break;
    } while (YES);
    
    [profile removeObjectForKey:@"lastTime"];
    [self cacheProfile:profile];
    return profile;
}

#pragma mark - MKMUserDataSource

- (nullable DIMPrivateKey *)privateKeyForSignatureOfUser:(DIMID *)user {
    return [DIMPrivateKey loadKeyWithIdentifier:user.address];
}

- (nullable NSArray<DIMPrivateKey *> *)privateKeysForDecryptionOfUser:(DIMID *)user {
    DIMPrivateKey *key = [DIMPrivateKey loadKeyWithIdentifier:user.address];
    if (key == nil) {
        return nil;
    }
    return [[NSArray alloc] initWithObjects:key, nil];
}

- (nullable NSArray<DIMID *> *)contactsOfUser:(DIMID *)user {
    NSArray *contacts = [_contactsTable objectForKey:user.address];
    if (!contacts) {
        contacts = [self reloadContactsWithUser:user];
        if (contacts.count > 0) {
            [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];
        }
    }
    return contacts;
}

#pragma mark - MKMGroupDataSource

- (nullable DIMID *)founderOfGroup:(DIMID *)grp {
    DIMMeta *meta = DIMMetaForID(grp);
    NSArray<DIMID *> *members = [self membersOfGroup:grp];
    for (DIMID *member in members) {
        // if the user's public key matches with the group's meta,
        // it means this meta was generate by the user's private key
        if ([meta matchPublicKey:[DIMMetaForID(member) key]]) {
            return member;
        }
    }
    return nil;
}

- (nullable DIMID *)ownerOfGroup:(DIMID *)grp {
    if (grp.type == MKMNetwork_Polylogue) {
        // the polylogue's owner is its founder
        return [self founderOfGroup:grp];
    }
    // TODO:
    return nil;
}

- (nullable NSArray<DIMID *> *)membersOfGroup:(DIMID *)group {
    // TODO: cache it
    return [self loadMembersWithGroupID:group];
}

@end
