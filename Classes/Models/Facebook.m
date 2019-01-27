//
//  Facebook.m
//  DIM
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"

#import "MKMImmortals.h"

#import "Facebook.h"

NSString *search_number(UInt32 code) {
    NSMutableString *number;
    number = [[NSMutableString alloc] initWithFormat:@"%010u", (unsigned int)code];;
    if ([number length] == 10) {
        [number insertString:@"-" atIndex:6];
        [number insertString:@"-" atIndex:3];
    }
    return number;
}

NSString *account_title(const MKMAccount *account) {
    NSString *name = account.name;
    NSString *number = search_number(account.number);
    return [NSString stringWithFormat:@"%@ (%@)", name, number];
}

NSString *group_title(const MKMGroup *group) {
    NSString *name = group.name;
    NSUInteger count = group.members.count;
    return [NSString stringWithFormat:@"%@ (%lu)", name, (unsigned long)count];
}

#pragma mark -

static inline NSString *document_directory(void) {
    NSArray *paths;
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask, YES);
    return paths.firstObject;
}

static inline NSArray *scan_barrack(void) {
    NSMutableArray *mArray = [[NSMutableArray alloc] init];
    
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *de;
    de = [fm enumeratorAtPath:dir];
    
    NSString *seed;
    NSString *addr;
    NSString *idstr;
    NSDictionary *dict;
    
    NSString *path;
    while (path = [de nextObject]) {
        //NSLog(@"path: %@", path);
        if ([path hasSuffix:@"/meta.plist"]) {
            addr = [path substringToIndex:(path.length - 11)];
            path = [dir stringByAppendingPathComponent:path];
            dict = [NSDictionary dictionaryWithContentsOfFile:path];
            seed = [dict objectForKey:@"seed"];
            idstr = [NSString stringWithFormat:@"%@@%@", seed, addr];
            NSLog(@"scan barrack -> number: %@, ID: %@", search_number([MKMID IDWithID:idstr].number), idstr);
            [mArray addObject:idstr];
        }
    }
    
    return mArray;
}

@interface Facebook () {
    
    MKMImmortals *_immortals;
    
    NSMutableArray *_contacts;
}

@end

@implementation Facebook

SingletonImplementations(Facebook, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        // immortal accounts
        _immortals = [[MKMImmortals alloc] init];
#if DEBUG
        MKMUser *user;
        user = [_immortals userWithID:[MKMID IDWithID:MKM_MONKEY_KING_ID]];
        [[DIMClient sharedInstance] addUser:user];
        user = [_immortals userWithID:[MKMID IDWithID:MKM_IMMORTAL_HULK_ID]];
        [[DIMClient sharedInstance] addUser:user];
#endif
        
        // contacts
        _contacts = [[NSMutableArray alloc] init];
#if DEBUG
        [_contacts addObject:MKM_MONKEY_KING_ID];
        [_contacts addObject:MKM_IMMORTAL_HULK_ID];
#endif
        
        NSArray *arr = scan_barrack();
        for (id item in arr) {
            if (![_contacts containsObject:item]) {
                [_contacts addObject:item];
            }
        }
        
        // delegates
        MKMBarrack *barrack = [MKMBarrack sharedInstance];
        barrack.accountDelegate    = self;
        barrack.userDataSource     = self;
        barrack.userDelegate       = self;
        barrack.groupDataSource    = self;
        barrack.groupDelegate      = self;
        barrack.memberDelegate     = self;
        barrack.chatroomDataSource = self;
        barrack.entityDataSource   = self;
        barrack.profileDataSource  = self;
    }
    return self;
}

- (MKMID *)IDWithAddress:(const MKMAddress *)address {
    MKMID *ID;
    for (id item in _contacts) {
        ID = [MKMID IDWithID:item];
        if ([ID.address isEqual:address]) {
            return ID;
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
        ID = [MKMID IDWithID:idstr];
        NSLog(@"Address -> number: %@, ID: %@", search_number(ID.number), ID);
    }
    
    return ID;
}

#pragma mark - MKMAccountDelegate

- (MKMAccount *)accountWithID:(const MKMID *)ID {
    MKMAccount *contact = [_immortals accountWithID:ID];
    if (contact) {
        return contact;
    }
    
    NSArray *users = [DIMClient sharedInstance].users;
    for (contact in users) {
        if ([contact.ID isEqual:ID]) {
            return contact;
        }
    }
    
    // create with ID and public key
    MKMPublicKey *PK = MKMPublicKeyForID(ID);
    if (PK) {
        contact = [[MKMAccount alloc] initWithID:ID publicKey:PK];
    } else {
        NSAssert(false, @"failed to get PK for user: %@", ID);
    }
    
    return contact;
}

#pragma mark - MKMUserDataSource

- (NSInteger)numberOfContactsInUser:(const MKMUser *)user {
    NSInteger count = 0;
    
    count = _contacts.count;
    
    return count;
}

- (MKMID *)user:(const MKMUser *)user contactAtIndex:(NSInteger)index {
    MKMID *ID = nil;
    
    ID = [_contacts objectAtIndex:index];
    ID = [MKMID IDWithID:ID];
    
    return ID;
}

#pragma mark MKMUserDelegate

- (MKMUser *)userWithID:(const MKMID *)ID {
    MKMUser *user = [_immortals userWithID:ID];
    if (user) {
        return user;
    }
    
    // create with ID and public key
    MKMPublicKey *PK = MKMPublicKeyForID(ID);
    if (PK) {
        user = [[MKMUser alloc] initWithID:ID publicKey:PK];
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

- (MKMID *)founderForGroupID:(const MKMID *)ID {
    // TODO:
    return nil;
}

- (MKMID *)ownerForGroupID:(const MKMID *)ID {
    // TODO:
    return nil;
}

- (NSInteger)numberOfMembersInGroup:(const MKMGroup *)grp {
    // TODO:
    return 0;
}

- (MKMID *)group:(const MKMGroup *)grp memberAtIndex:(NSInteger)index {
    // TODO:
    return nil;
}

#pragma mark MKMGroupDelegate

- (MKMGroup *)groupWithID:(const MKMID *)ID {
    MKMGroup *group = nil;
    
    // get founder of this group
    MKMID *founder = [self founderForGroupID:ID];
    if (!founder) {
        NSAssert(false, @"founder not found for group: %@", ID);
        return  nil;
    }
    
    // create it
    if (ID.type == MKMNetwork_Polylogue) {
        group = [[MKMPolylogue alloc] initWithID:ID founderID:founder];
    } else if (ID.type == MKMNetwork_Chatroom) {
        group = [[MKMChatroom alloc] initWithID:ID founderID:founder];
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
        MKMChatroom *chatroom = (MKMChatroom *)group;
        count = [self numberOfAdminsInChatroom:chatroom];
        for (index = 0; index < count; ++index) {
            [chatroom addAdmin:[self chatroom:chatroom adminAtIndex:index]];
        }
    }
    
    return group;
}

#pragma mark MKMMemberDelegate

- (MKMMember *)memberWithID:(const MKMID *)ID groupID:(const MKMID *)gID {
    // TODO:
    return nil;
}

#pragma mark MKMChatroomDataSource

- (MKMID *)chatroom:(const MKMChatroom *)grp adminAtIndex:(NSInteger)index {
    // TODO:
    return nil;
}

- (NSInteger)numberOfAdminsInChatroom:(const MKMChatroom *)grp {
    // TODO:
    return 0;
}

#pragma mark - MKMEntityDataSource

- (MKMMeta *)metaForEntityID:(const MKMID *)ID {
    MKMMeta *meta = nil;
    
    // TODO:
    MKMBarrack *barrack = [MKMBarrack sharedInstance];
    meta = [barrack loadMetaForEntityID:ID];
    if (meta) {
        return meta;
    }
    
    return [_immortals metaForEntityID:ID];
}

#pragma mark - MKMProfileDataSource

- (MKMProfile *)profileForID:(const MKMID *)ID {
    // TODO:
    if (MKMNetwork_IsPerson(ID.type)) {
        return [_immortals profileForID:ID];
    }
    // Not Found
    return nil;
}

@end
