//
//  Facebook.m
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSDate+Timestamp.h"

#import "MKMImmortals.h"

#import "User.h"
#import "MessageProcessor+Station.h"

#import "Client.h"
#import "Station+Handler.h"
#import "Facebook+Register.h"

#import "Facebook.h"

@interface MKMUser (Hacking)

@property (strong, nonatomic) MKMContactListM *contacts;

@end

typedef NSMutableDictionary<const DIMAddress *, DIMProfile *> ProfileTableM;

@interface Facebook () {
    
    MKMImmortals *_immortals;
    
    NSMutableDictionary<DIMAddress *, MKMContactListM *> *_contactsTable;
    
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
        barrack.accountDelegate    = self;
        barrack.userDataSource     = self;
        barrack.userDelegate       = self;
        barrack.groupDataSource    = self;
        barrack.groupDelegate      = self;
        barrack.memberDelegate     = self;
        barrack.chatroomDataSource = self;
        barrack.entityDataSource   = self;
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
        for (MKMID *ID in users) {
            user = [self userWithID:ID];
            [client addUser:user];
        }
    }
    return self;
}

- (DIMID *)IDWithAddress:(const DIMAddress *)address {
    DIMID *ID;
//    for (id item in _contacts) {
//        ID = [DIMID IDWithID:item];
//        if ([ID.address isEqual:address]) {
//            return ID;
//        }
//    }
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
    }
    
    return ID;
}

- (void)addContact:(const DIMID *)contactID user:(const DIMUser *)user {
    MKMContactListM *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts) {
        if ([contacts containsObject:contactID]) {
            NSLog(@"contact %@ already exists, user: %@", contactID, user.ID);
            return ;
        } else {
            [contacts addObject:contactID];
        }
    } else {
        contacts = [[MKMContactListM alloc] initWithCapacity:1];
        [contacts addObject:contactID];
        [_contactsTable setObject:contacts forKey:user.ID.address];
    }
    [user addContact:contactID];
    [self flushContactsWithUser:user];
}

- (void)removeContact:(const DIMID *)contactID user:(const DIMUser *)user {
    MKMContactListM *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts) {
        if ([contacts containsObject:contactID]) {
            [contacts removeObject:contactID];
        } else {
            NSLog(@"contact %@ not exists, user: %@", contactID, user.ID);
            return ;
        }
    } else {
        NSLog(@"user %@ doesn't has contact yet", user.ID);
        return ;
    }
    [user removeContact:contactID];
    [self flushContactsWithUser:user];
}

// {document_directory}/.mkm/{address}/contacts.plist
- (void)flushContactsWithUser:(const DIMUser *)user {
    Client *client = [Client sharedInstance];
    
    MKMContactListM *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts.count > 0) {
        NSString *dir = document_directory();
        NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/contacts.plist", dir, user.ID.address];
        [contacts writeToFile:path atomically:YES];
        NSLog(@"contacts updated: %@", contacts);
        [client postNotificationName:@"ContactsUpdated"];
    } else {
        NSLog(@"no contacts");
    }
}

// {document_directory}/.mkm/{address}/contacts.plist
- (ContactTable *)reloadContactsWithUser:(DIMUser *)user {
    NSString *dir = document_directory();
    NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/contacts.plist", dir, user.ID.address];
    
    MKMContactListM *contacts = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        contacts = [[MKMContactListM alloc] initWithContentsOfFile:path];
    }
    
    if (contacts) {
        [_contactsTable setObject:contacts forKey:user.ID.address];
    } else {
        [_contactsTable removeObjectForKey:user.ID.address];
    }
    user.contacts = contacts;
    return contacts;
}

- (void)setProfile:(DIMProfile *)profile forID:(const DIMID *)ID {
    if (profile) {
        if ([profile.ID isEqual:ID]) {
            [_profileTable setObject:profile forKey:ID.address];
        } else {
            NSAssert(false, @"profile error: %@, ID = %@", profile, ID);
        }
    } else {
        [_profileTable removeObjectForKey:ID.address];
    }
}

#pragma mark - MKMAccountDelegate

- (DIMAccount *)accountWithID:(const DIMID *)ID {
    DIMAccount *contact = [_immortals accountWithID:ID];
    if (contact) {
        return contact;
    }
    
    NSArray *users = [Client sharedInstance].users;
    for (contact in users) {
        if ([contact.ID isEqual:ID]) {
            return contact;
        }
    }
    
    // create with ID and public key
    DIMPublicKey *PK = MKMPublicKeyForID(ID);
    if (PK) {
        contact = [[DIMAccount alloc] initWithID:ID publicKey:PK];
    } else {
        NSLog(@"failed to get PK for user: %@", ID);
    }
    
    return contact;
}

#pragma mark - MKMUserDataSource

- (NSInteger)numberOfContactsInUser:(const DIMUser *)user {
    DIMID *ID = user.ID;
    
    NSArray *contacts = [_contactsTable objectForKey:ID.address];
    if (!contacts) {
        contacts = [self reloadContactsWithUser:user];
    }
    
    return contacts.count;
}

- (DIMID *)user:(const DIMUser *)user contactAtIndex:(NSInteger)index {
    DIMID *ID = user.ID;
    
    NSArray *contacts = [_contactsTable objectForKey:ID.address];
    if (!contacts) {
        contacts = [self reloadContactsWithUser:user];
    }
    
    ID = [contacts objectAtIndex:index];
    return [DIMID IDWithID:ID];
}

#pragma mark MKMUserDelegate

- (DIMUser *)userWithID:(const DIMID *)ID {
    DIMUser *user = [_immortals userWithID:ID];
    if (user) {
        return user;
    }
    
    // create with ID and public key
    DIMPublicKey *PK = MKMPublicKeyForID(ID);
    if (PK) {
        user = [[DIMUser alloc] initWithID:ID publicKey:PK];
    } else {
        NSAssert(false, @"failed to get PK for user: %@", ID);
    }
    
    // add contacts
    NSInteger count = [self numberOfContactsInUser:user];
    for (NSInteger index = 0; index < count; ++index) {
        [user addContact:[self user:user contactAtIndex:index]];
    }
    
    return user;
}

#pragma mark - MKMGroupDataSource

- (DIMID *)founderForGroupID:(const DIMID *)ID {
    // TODO:
    return nil;
}

- (DIMID *)ownerForGroupID:(const DIMID *)ID {
    // TODO:
    return nil;
}

- (NSInteger)numberOfMembersInGroup:(const DIMGroup *)grp {
    // TODO:
    return 0;
}

- (DIMID *)group:(const DIMGroup *)grp memberAtIndex:(NSInteger)index {
    // TODO:
    return nil;
}

#pragma mark MKMGroupDelegate

- (DIMGroup *)groupWithID:(const DIMID *)ID {
    DIMGroup *group = nil;
    
    // get founder of this group
    DIMID *founder = [self founderForGroupID:ID];
    if (!founder) {
        NSAssert(false, @"founder not found for group: %@", ID);
        return  nil;
    }
    
    // create it
    if (ID.type == MKMNetwork_Polylogue) {
        group = [[DIMPolylogue alloc] initWithID:ID founderID:founder];
    } else if (ID.type == MKMNetwork_Chatroom) {
        group = [[DIMChatroom alloc] initWithID:ID founderID:founder];
    } else {
        NSAssert(false, @"group error: %@", ID);
    }
    // set owner
    group.owner = [self ownerForGroupID:ID];
    // add members
    NSInteger count = [self numberOfMembersInGroup:group];
    NSInteger index;
    for (index = 0; index < count; ++index) {
        [group addMember:[self group:group memberAtIndex:index]];
    }
    
    if (ID.type == MKMNetwork_Chatroom) {
        // add admins
        DIMChatroom *chatroom = (DIMChatroom *)group;
        count = [self numberOfAdminsInChatroom:chatroom];
        for (index = 0; index < count; ++index) {
            [chatroom addAdmin:[self chatroom:chatroom adminAtIndex:index]];
        }
    }
    
    return group;
}

#pragma mark MKMMemberDelegate

- (DIMMember *)memberWithID:(const DIMID *)ID groupID:(const DIMID *)gID {
    // TODO:
    return nil;
}

#pragma mark MKMChatroomDataSource

- (DIMID *)chatroom:(const DIMChatroom *)grp adminAtIndex:(NSInteger)index {
    // TODO:
    return nil;
}

- (NSInteger)numberOfAdminsInChatroom:(const DIMChatroom *)grp {
    // TODO:
    return 0;
}

#pragma mark - MKMEntityDataSource

- (DIMMeta *)metaForEntityID:(const DIMID *)ID {
    DIMMeta *meta = nil;
    
    // TODO:
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    meta = [barrack loadMetaForEntityID:ID];
    if (meta) {
        return meta;
    }
    
    return [_immortals metaForEntityID:ID];
}

#pragma mark - MKMProfileDataSource

- (DIMProfile *)profileForID:(const DIMID *)ID {
    DIMProfile *profile = nil;
    
    // (a) get from profile cache
    profile = [_profileTable objectForKey:ID.address];
    if (profile) {
        // TODO: check cache expires
        NSNumber *timestamp = [profile objectForKey:@"lastTime"];
        if (timestamp) {
            NSDate *lastTime = NSDateFromNumber(timestamp);
            NSTimeInterval ti = [lastTime timeIntervalSinceNow];
            if (fabs(ti) > 300) {
                [_profileTable removeObjectForKey:ID.address];
            }
        }
        
        return profile;
    }
    
    // (b) load from "Documents/.mkm/{address}/profile.plist"
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    dir = [dir stringByAppendingPathComponent:ID.address];
    NSString *path = [dir stringByAppendingPathComponent:@"profile.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        profile = [DIMProfile profileWithProfile:dict];
        NSLog(@"loaded profile from %@", path);
    } else {
        // (c) try immortals
        if (MKMNetwork_IsPerson(ID.type)) {
            profile = [_immortals profileForID:ID];
        }
    }
    
    // (d) query from network
    if (!profile) {
        profile = [[DIMProfile alloc] initWithID:ID];
        
        Client *client = [Client sharedInstance];
        Station *server = client.currentStation;
        [server queryProfileForID:ID];
    }
    NSDate *now = [[NSDate alloc] init];
    [profile setObject:NSNumberFromDate(now) forKey:@"lastTime"];
    
    [self setProfile:profile forID:ID];
    return profile;
}

@end
