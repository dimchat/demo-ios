//
//  Facebook.m
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSDate+Timestamp.h"
#import "NSNotificationCenter+Extension.h"

#import "MKMImmortals.h"

#import "User.h"

#import "Client.h"
#import "Facebook+Register.h"

#import "Facebook.h"

const NSString *kNotificationName_ContactsUpdated = @"ContactsUpdated";

typedef NSMutableDictionary<const DIMAddress *, DIMProfile *> ProfileTableM;

@interface Facebook () {
    
    MKMImmortals *_immortals;
    
    NSMutableDictionary<const DIMAddress *, NSMutableArray<const DIMID *> *> *_contactsTable;
    
    ProfileTableM *_profileTable;
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
        _profileTable = [[ProfileTableM alloc] init];
        
        // delegates
        DIMBarrack *barrack = [DIMBarrack sharedInstance];
        barrack.metaDataSource     = self;
        barrack.entityDataSource   = self;
        barrack.accountDelegate    = self;
        barrack.userDataSource     = self;
        barrack.userDelegate       = self;
        barrack.groupDataSource    = self;
        barrack.groupDelegate      = self;
        barrack.memberDelegate     = self;
        barrack.chatroomDataSource = self;
        barrack.profileDataSource  = self;
        
        // scan users
        NSArray *users = [self scanUserIDList];
#if DEBUG && 0
        NSMutableArray *mArray;
        if (users.count > 0) {
            mArray = [users mutableCopy];
        } else {
            mArray = [[NSMutableArray alloc] initWithCapacity:2];
        }
        [mArray addObject:[DIMID IDWithID:MKM_IMMORTAL_HULK_ID]];
        [mArray addObject:[DIMID IDWithID:MKM_MONKEY_KING_ID]];
        users = mArray;
#endif
        // add users
        Client *client = [Client sharedInstance];
        DIMUser *user;
        for (DIMID *ID in users) {
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
    if ([notification.name isEqual:kNotificationName_ProfileUpdated]) {
        DIMProfileCommand *cmd = (DIMProfileCommand *)notification.userInfo;
        DIMProfile *profile = cmd.profile;
        if ([profile.ID isEqual:cmd.ID]) {
            [profile removeObjectForKey:@"lastTime"];
            [self saveProfile:profile forEntityID:profile.ID];
        }
    }
}

- (const DIMID *)IDWithAddress:(const DIMAddress *)address {
    DIMID *ID;
    NSArray *tables = _contactsTable.allValues;
    for (NSArray *list in tables) {
        for (id item in list) {
            ID = [DIMID IDWithID:item];
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
        ID = [DIMID IDWithID:idstr];
        NSLog(@"Address -> number: %@, ID: %@", search_number(ID.number), ID);
    } else {
        NSLog(@"meta file not exists: %@", path);
    }
    
    return ID;
}

- (void)addStation:(const DIMID *)stationID provider:(const DIMServiceProvider *)sp {
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
- (void)flushContactsWithUser:(const DIMUser *)user {
    
    NSMutableArray<const DIMID *> *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts.count > 0) {
        NSString *dir = document_directory();
        NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/contacts.plist", dir, user.ID.address];
        [contacts writeToFile:path atomically:YES];
        NSLog(@"contacts updated: %@", contacts);
        [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];
    } else {
        NSLog(@"no contacts");
    }
}

// {document_directory}/.mkm/{address}/contacts.plist
- (ContactTable *)reloadContactsWithUser:(DIMUser *)user {
    NSString *dir = document_directory();
    NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/contacts.plist", dir, user.ID.address];
    
    NSMutableArray<const DIMID *> *contacts = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        contacts = [[NSMutableArray alloc] initWithContentsOfFile:path];
    }
    
    if (contacts) {
        [_contactsTable setObject:contacts forKey:user.ID.address];
    } else {
        [_contactsTable removeObjectForKey:user.ID.address];
    }
    return contacts;
}

- (void)setProfile:(const DIMProfile *)profile forID:(const DIMID *)ID {
    if (profile) {
        if ([profile.ID isEqual:ID]) {
            [_profileTable setObject:[profile copy] forKey:ID.address];
        } else {
            NSAssert(false, @"profile error: %@, ID = %@", profile, ID);
        }
    } else {
        [_profileTable removeObjectForKey:ID.address];
    }
}

#pragma mark - MKMMetaDataSource

- (const DIMMeta *)metaForID:(const DIMID *)ID {
    const DIMMeta *meta = nil;
    
    if (MKMNetwork_IsPerson(ID.type)) {
        meta = [_immortals metaForID:ID];
    }
    
    // TODO: load meta from database
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    meta = [barrack loadMetaForID:ID];
    
    if (!meta) {
        // query from DIM network
        Client *client = [Client sharedInstance];
        [client queryMetaForID:ID];
        NSLog(@"querying meta for ID: %@", ID);
    }
    
    return meta;
}

#pragma mark - MKMEntityDataSource

- (const DIMMeta *)metaForEntity:(const DIMEntity *)entity {
    return [self metaForID:entity.ID];
}

- (NSString *)nameOfEntity:(const DIMEntity *)entity {
    DIMProfile *profile = [self profileForID:entity.ID];
    return profile.name;
}

#pragma mark - MKMAccountDelegate

- (DIMAccount *)accountWithID:(const DIMID *)ID {
    DIMAccount *account = [_immortals accountWithID:ID];
    if (account) {
        return account;
    }
    
    NSArray *users = [Client sharedInstance].users;
    for (account in users) {
        if ([account.ID isEqual:ID]) {
            return account;
        }
    }
    
    // check meta
    const DIMMeta *meta = DIMMetaForID(ID);
    if (!meta) {
        NSLog(@"meta not found: %@", ID);
    }
    
    account = [[DIMAccount alloc] initWithID:ID];
    return account;
}

#pragma mark - MKMUserDataSource

- (NSInteger)numberOfContactsInUser:(const DIMUser *)user {
    const DIMID *ID = user.ID;
    
    NSArray *contacts = [_contactsTable objectForKey:ID.address];
    if (!contacts) {
        contacts = [self reloadContactsWithUser:user];
    }
    
    return contacts.count;
}

- (const DIMID *)user:(const DIMUser *)user contactAtIndex:(NSInteger)index {
    const DIMID *ID = user.ID;
    
    NSArray *contacts = [_contactsTable objectForKey:ID.address];
    if (!contacts) {
        contacts = [self reloadContactsWithUser:user];
    }
    
    ID = [contacts objectAtIndex:index];
    return [DIMID IDWithID:ID];
}

- (BOOL)user:(const DIMUser *)user addContact:(const DIMID *)contact {
    NSLog(@"user %@ add contact %@", user, contact);
    NSMutableArray<const DIMID *> *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts) {
        if ([contacts containsObject:contact]) {
            NSLog(@"contact %@ already exists, user: %@", contact, user.ID);
            return NO;
        } else {
            [contacts addObject:contact];
        }
    } else {
        contacts = [[NSMutableArray alloc] initWithCapacity:1];
        [contacts addObject:contact];
        [_contactsTable setObject:contacts forKey:user.ID.address];
    }
    [self flushContactsWithUser:user];
    return YES;
}

- (BOOL)user:(const DIMUser *)user removeContact:(const DIMID *)contact {
    NSLog(@"user %@ remove contact %@", user, contact);
    NSMutableArray<const DIMID *> *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts) {
        if ([contacts containsObject:contact]) {
            [contacts removeObject:contact];
        } else {
            NSLog(@"contact %@ not exists, user: %@", contact, user.ID);
            return NO;
        }
    } else {
        NSLog(@"user %@ doesn't has contact yet", user.ID);
        return NO;
    }
    [self flushContactsWithUser:user];
    return YES;
}

#pragma mark MKMUserDelegate

- (DIMUser *)userWithID:(const DIMID *)ID {
    DIMUser *user = [_immortals userWithID:ID];
    if (user) {
        return user;
    }
    
    NSArray *users = [Client sharedInstance].users;
    for (user in users) {
        if ([user.ID isEqual:ID]) {
            return user;
        }
    }
    
    // check meta
    const DIMMeta *meta = DIMMetaForID(ID);
    if (!meta) {
        NSLog(@"meta not found: %@", ID);
    }
    
    user = [[DIMUser alloc] initWithID:ID];
    return user;
}

#pragma mark - MKMGroupDataSource

- (const DIMID *)founderOfGroup:(const DIMGroup *)grp {
    const DIMMeta *groupMeta = grp.meta;
    NSInteger count = [self numberOfMembersInGroup:grp];
    const DIMID *member;
    for (NSInteger index = 0; index < count; ++index) {
        member = [self group:grp memberAtIndex:index];
        // if the user's public key matches with the group's meta,
        // it means this meta was generate by the user's private key
        if ([groupMeta matchPublicKey:DIMPublicKeyForID(member)]) {
            return member;
        }
    }
    return nil;
}

- (const DIMID *)ownerOfGroup:(const DIMGroup *)grp {
    if (grp.ID.type == MKMNetwork_Polylogue) {
        // the polylogue's owner is its founder
        return [self founderOfGroup:grp];
    }
    // TODO:
    return nil;
}

- (NSInteger)numberOfMembersInGroup:(const DIMGroup *)grp {
    // TODO: cache it
    NSArray<const DIMID *> *list = [self loadMembersWithGroupID:grp.ID];
    return list.count;
}

- (const DIMID *)group:(const DIMGroup *)grp memberAtIndex:(NSInteger)index {
    // TODO: cache it
    NSArray<const DIMID *> *list = [self loadMembersWithGroupID:grp.ID];
    if (index < list.count && index >= 0) {
        return [list objectAtIndex:index];
    } else {
        return nil;
    }
}

#pragma mark MKMGroupDelegate

- (DIMGroup *)groupWithID:(const DIMID *)ID {
    DIMGroup *group = nil;
    
    // check meta
    const DIMMeta *meta = DIMMetaForID(ID);
    if (!meta) {
        NSLog(@"meta not found: %@", ID);
    }
    
    // create it
    if (ID.type == MKMNetwork_Polylogue) {
        group = [[DIMPolylogue alloc] initWithID:ID];
    } else if (ID.type == MKMNetwork_Chatroom) {
        group = [[DIMChatroom alloc] initWithID:ID];
    } else {
        NSAssert(false, @"group error: %@", ID);
    }
    return group;
}

- (BOOL)group:(const DIMGroup *)group addMember:(const DIMID *)member {
    NSArray<const DIMID *> *members = group.members;
    if ([members containsObject:member]) {
        NSAssert(false, @"member already exists: %@, %@", member, group);
        return NO;
    }
    NSMutableArray *mArray = [members mutableCopy];
    [mArray addObject:members];
    return [self saveMembers:mArray withGroupID:group.ID];
}

- (BOOL)group:(const DIMGroup *)group removeMember:(const DIMID *)member {
    NSArray<const DIMID *> *members = group.members;
    if (![members containsObject:member]) {
        NSAssert(false, @"member not exists: %@, %@", member, group);
        return NO;
    }
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:(members.count - 1)];
    for (const DIMID *item in members) {
        if ([item isEqual:member]) {
            continue;
        }
        [mArray addObject:item];
    }
    return [self saveMembers:mArray withGroupID:group.ID];
}

#pragma mark MKMMemberDelegate

- (DIMMember *)memberWithID:(const DIMID *)ID groupID:(const DIMID *)gID {
    // TODO:
    return nil;
}

#pragma mark MKMChatroomDataSource

- (const DIMID *)chatroom:(const DIMChatroom *)grp adminAtIndex:(NSInteger)index {
    // TODO:
    return nil;
}

- (NSInteger)numberOfAdminsInChatroom:(const DIMChatroom *)grp {
    // TODO:
    return 0;
}

#pragma mark - MKMProfileDataSource

- (DIMProfile *)profileForID:(const DIMID *)ID {
    DIMProfile *profile = nil;
    
    // try from profile cache
    profile = [_profileTable objectForKey:ID.address];
    if (profile) {
        // check cache expires
        NSNumber *timestamp = [profile objectForKey:@"lastTime"];
        if (timestamp) {
            NSDate *lastTime = NSDateFromNumber(timestamp);
            NSTimeInterval ti = [lastTime timeIntervalSinceNow];
            if (fabs(ti) > 300) {
                NSLog(@"profile expired: %@", lastTime);
                [_profileTable removeObjectForKey:ID.address];
            }
        } else {
            NSDate *now = [[NSDate alloc] init];
            [profile setObject:NSNumberFromDate(now) forKey:@"lastTime"];
        }
        
        return profile;
    }
    
    // update from network
    [[Client sharedInstance] queryProfileForID:ID];
    
    // try from "Documents/.mkm/{address}/profile.plist"
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:(NSString *)ID.address];
    NSString *path = [dir stringByAppendingPathComponent:@"profile.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"loaded profile from %@", path);
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        profile = [DIMProfile profileWithProfile:dict];
    }
    
    if (profile) {
        [profile removeObjectForKey:@"lastTime"];
    } else {
        // try immortals
        if (MKMNetwork_IsPerson(ID.type)) {
            profile = [_immortals profileForID:ID];
        }
        
        // place an empty profile for cache
        if (!profile) {
            profile = [[DIMProfile alloc] initWithID:ID];
        }
    }
    
    [self setProfile:profile forID:ID];
    return profile;
}

@end
