// license: https://mit-license.org
//
//  SeChat : Secure/secret Chat Application
//
//                               Written in 2020 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2020 Albert Moky
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
//
//  DIMSharedFacebook.m
//  DIMP
//
//  Created by Albert Moky on 2020/12/13.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "DIMConstants.h"

#import "DIMAddressNameTable.h"
#import "DIMUserTable.h"

#import "DIMSharedFacebook.h"

typedef NSMutableArray<id<MKMID>> UserList;

@interface DIMSharedFacebook () {
    
    NSMutableArray<id<MKMUser>> *_allUsers;  // local users
    NSMutableDictionary<id<MKMID>, UserList *> *_userContacts;
    NSMutableDictionary<id<MKMID>, UserList *> *_groupMembers;
    NSMutableDictionary<id<MKMID>, UserList *> *_groupAssistants;
    UserList *_defaultAssistants;
}

@end

@implementation DIMSharedFacebook

- (instancetype)initWithDatabase:(id<DIMAccountDBI>)db {
    if (self = [super initWithDatabase:db]) {
        _allUsers          = nil;
        _userContacts      = [[NSMutableDictionary alloc] init];
        _groupMembers      = [[NSMutableDictionary alloc] init];
        _groupAssistants   = [[NSMutableDictionary alloc] init];
        _defaultAssistants = [[NSMutableArray alloc] init];
    }
    return self;
}

// Override
- (NSArray<id<MKMUser>> *)localUsers {
    if (!_allUsers) {
        NSArray<id<MKMUser>> *users = [super localUsers];
        if (users) {
            _allUsers = (NSMutableArray<id<MKMUser>> *)users;
        } else {
            _allUsers = [[NSMutableArray alloc] init];
        }
    }
    return _allUsers;
}

// Override
- (void)setCurrentUser:(id<MKMUser>)currentUser {
    id<DIMUserTable> table = (id<DIMUserTable>)[self database];
    [table setCurrentUser:currentUser.ID];
    // clear cache for reload
    [_allUsers removeAllObjects];
    [super setCurrentUser:currentUser];
}

// Override
- (NSArray<id<MKMID>> *)contactsOfUser:(id<MKMID>)user {
    UserList *contacts = [_userContacts objectForKey:user];
    if (!contacts) {
        contacts = (UserList *)[super contactsOfUser:user];
        if (!contacts) {
            // placeholder
            contacts = [[NSMutableArray alloc] init];
        }
        [_userContacts setObject:contacts forKey:user];
    }
    return contacts;
}

// Override
- (NSArray<id<MKMID>> *)membersOfGroup:(id<MKMID>)group {
    UserList *members = [_groupMembers objectForKey:group];
    if (!members) {
        members = (UserList *)[super membersOfGroup:group];
        if (!members) {
            // placeholder
            members = [[NSMutableArray alloc] init];
        }
        [_groupMembers setObject:members forKey:group];
    }
    return members;
}

// Override
- (BOOL)saveMembers:(NSArray<id<MKMID>> *)members group:(id<MKMID>)ID {
    BOOL ok = [super saveMembers:members group:ID];
    if (!ok) {
        return NO;
    }
    // erase cache for reload
    [_groupMembers removeObjectForKey:ID];
    // post notification
    NSDictionary *info = @{@"group": ID};
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNotificationName_GroupMembersUpdated
                      object:self userInfo:info];
    return YES;
}

// Override
- (NSArray<id<MKMID>> *)assistantsOfGroup:(id<MKMID>)group {
    UserList *assistants = [_groupAssistants objectForKey:group];
    if (!assistants) {
        assistants = (UserList *)[super assistantsOfGroup:group];
        if (!assistants) {
            // placeholder
            assistants = [[NSMutableArray alloc] init];
        }
        [_groupAssistants setObject:assistants forKey:group];
    }
    if ([assistants count] > 0) {
        return assistants;
    }
    // get from global setting
    assistants = _defaultAssistants;
    if ([assistants count] > 0) {
        return assistants;
    }
    // get from ANS
    DIMAddressNameServer *ans = [DIMClientFacebook ans];
    id<MKMID> bot = [ans getID:@"assistant"];
    if (bot) {
        return @[bot];
    } else {
        return nil;
    }
}

// Override
- (BOOL)isOwner:(id<MKMID>)member group:(id<MKMID>)group {
    id<MKMID> owner = [self ownerOfGroup:group];
    if (owner) {
        return [owner isEqual:member];
    }
    return [super isOwner:member group:group];
}

// Override
- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    BOOL ok = [super saveMeta:meta forID:ID];
    if (!ok) {
        return NO;
    }
    NSDictionary *info = @{
        @"ID": [ID string],
        @"meta": [meta dictionary],
    };
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNotificationName_MetaSaved object:self userInfo:info];
    return YES;
}

//- (nullable id<MKMMeta>)metaForID:(id<MKMID>)ID {
//    if (MKMIDIsBroadcast(ID)) {
//        // broadcast ID has no meta
//        return nil;
//    }
//    // try from database
//    id<MKMMeta> meta = [_database metaForID:ID];
//    if (!meta) {
//        // query from DIM network
//        DIMMessenger *messenger = [DIMMessenger sharedInstance];
//        [messenger queryMetaForID:ID];
//    }
//    return meta;
//}
//
//- (BOOL)saveDocument:(id<MKMDocument>)doc {
//    if (![self checkDocument:doc]) {
//        return NO;
//    }
//    [doc removeObjectForKey:PROFILE_EXPIRES_KEY];
//    if (![_database saveDocument:doc]) {
//        return NO;
//    }
//    NSDictionary *info = [doc dictionary];
//    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//    [nc postNotificationName:kNotificationName_DocumentUpdated object:self userInfo:info];
//    return YES;
//}
//
//- (nullable id<MKMDocument>)documentForID:(id<MKMID>)ID type:(nullable NSString *)type {
//    if (MKMIDIsBroadcast(ID)) {
//        // broadcast ID has no document
//        return nil;
//    }
//    // try from database
//    id<MKMDocument> doc = [_database documentForID:ID type:type];
//    if (!doc || [self isExpiredDocument:doc]) {
//        if (doc) {
//            // update EXPIRES value
//            NSDate *now = [[NSDate alloc] init];
//            NSTimeInterval timestamp = [now timeIntervalSince1970];
//            [doc setObject:@(timestamp + PROFILE_EXPIRES) forKey:PROFILE_EXPIRES_KEY];
//        }
//        // query from DIM network
//        DIMMessenger *messenger = [DIMMessenger sharedInstance];
//        [messenger queryDocumentForID:ID];
//    }
//    return doc;
//}
//
//- (BOOL)isExpiredDocument:(id<MKMDocument>)doc {
//    NSDate *now = [[NSDate alloc] init];
//    NSTimeInterval timestamp = [now timeIntervalSince1970];
//    NSNumber *expires = [doc objectForKey:PROFILE_EXPIRES_KEY];
//    if (!expires) {
//        // set expired time
//        [doc setObject:@(timestamp + PROFILE_EXPIRES) forKey:PROFILE_EXPIRES_KEY];
//        return NO;
//    }
//    return timestamp > [expires doubleValue];
//}
//
//- (BOOL)saveContacts:(NSArray<id<MKMID>> *)contacts user:(id<MKMID>)ID {
////    if (![self cacheContacts:contacts user:ID]) {
////        return NO;
////    }
//    BOOL OK = [_database saveContacts:contacts user:ID];
//    if (OK) {
//        NSDictionary *info = @{@"ID": ID};
//        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//        [nc postNotificationName:kNotificationName_ContactsUpdated
//                          object:self userInfo:info];
//    }
//    return OK;
//}
//}

@end

@implementation DIMSharedFacebook (User)

- (OKPair<NSString *, NSString *> *)avatarForUser:(id<MKMID>)user {
    NSString *url = nil;
    id<MKMDocument> doc = [self documentForID:user type:@"*"];
    if (doc) {
        if ([doc conformsToProtocol:@protocol(MKMVisa)]) {
            url = [(id<MKMVisa>)doc avatar];
        } else {
            url = [doc propertyForKey:@"avatar"];
        }
    }
    if ([url length] == 0) {
        id a = nil, b = nil;
        return [[OKPair alloc] initWithFirst:a second:b];
    }
    // TODO: download avatar
//    DIMFileServer *http = [DIMFileServer sharedInstance];
//    NSString *path = [http downloadDataFromURL:url];
    NSString *path = url;
    return [[OKPair alloc] initWithFirst:path second:url];
}

- (BOOL)savePrivateKey:(id<MKMPrivateKey>)SK
              withType:(NSString *)type
               forUser:(id<MKMID>)user {
    id<DIMAccountDBI> db = [self database];
    return [db savePrivateKey:SK withType:type forUser:user];
}

- (BOOL)addUser:(id<MKMID>)user {
    id<DIMAccountDBI> db = [self database];
    UserList *allUsers = (UserList *)[db localUsers];
    NSAssert(allUsers, @"allUsers would not be nil here");
    NSInteger pos = [allUsers indexOfObject:user];
    if (pos != NSNotFound) {
        // already exists
        return NO;
    }
    [allUsers addObject:user];
    if ([db saveLocalUsers:allUsers]) {
        // clear cache for reload
        [_allUsers removeAllObjects];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)removeUser:(id<MKMID>)user {
    id<DIMAccountDBI> db = [self database];
    UserList *allUsers = (UserList *)[db localUsers];
    NSAssert(allUsers, @"allUsers would not be nil here");
    NSInteger pos = [allUsers indexOfObject:user];
    if (pos == NSNotFound) {
        // not exists
        return NO;
    }
    [allUsers removeObjectAtIndex:pos];
    if ([db saveLocalUsers:allUsers]) {
        // clear cache for reload
        [_allUsers removeAllObjects];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)saveContacts:(NSArray<id<MKMID>> *)contacts user:(id<MKMID>)user {
    id<DIMAccountDBI> db = [self database];
    if ([db saveContacts:contacts user:user]) {
        // erase cache for reload
        [_userContacts removeObjectForKey:user];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)addContact:(id<MKMID>)contact user:(id<MKMID>)user {
    UserList *allContacts = (UserList *)[self contactsOfUser:user];
    NSAssert(allContacts, @"allContacts would not be nil here: %@", user);
    NSInteger pos = [allContacts indexOfObject:contact];
    if (pos != NSNotFound) {
        // already exists
        return NO;
    }
    [allContacts addObject:contact];
    return [self saveContacts:allContacts user:user];
}

- (BOOL)removeContact:(id<MKMID>)contact user:(id<MKMID>)user {
    UserList *allContacts = (UserList *)[self contactsOfUser:user];
    NSAssert(allContacts, @"allContacts would not be nil here: %@", user);
    NSInteger pos = [allContacts indexOfObject:contact];
    if (pos != NSNotFound) {
        // already exists
        return NO;
    }
    [allContacts removeObjectAtIndex:pos];
    return [self saveContacts:allContacts user:user];
}

@end

@implementation DIMSharedFacebook (Group)

- (BOOL)addMember:(id<MKMID>)member group:(id<MKMID>)group {
    UserList *allMembers = (UserList *)[self membersOfGroup:group];
    NSAssert(allMembers, @"allMembers would not be nil here: %@", group);
    NSInteger pos = [allMembers indexOfObject:member];
    if (pos != NSNotFound) {
        // already exists
        return NO;
    }
    [allMembers addObject:member];
    return [self saveMembers:allMembers group:group];
}

- (BOOL)removeMember:(id<MKMID>)member group:(id<MKMID>)group {
    UserList *allMembers = (UserList *)[self membersOfGroup:group];
    NSAssert(allMembers, @"allMembers would not be nil here: %@", group);
    NSInteger pos = [allMembers indexOfObject:member];
    if (pos == NSNotFound) {
        // not exists
        return NO;
    }
    [allMembers removeObjectAtIndex:pos];
    return [self saveMembers:allMembers group:group];
}

- (BOOL)containsMember:(id<MKMID>)member group:(id<MKMID>)group {
    NSArray<id<MKMID>> *allMembers = [self membersOfGroup:group];
    if ([allMembers containsObject:member]) {
        return YES;
    }
    return [self isOwner:member group:group];
}

- (BOOL)removeGroup:(id<MKMID>)group {
    // TODO: remove group from db
//    id<DIMAccountDBI> db = [self database];
//    return [db removeGroup:group];
    return NO;
}

- (BOOL)addAssistant:(id<MKMID>)bot group:(id<MKMID>)group {
    if ([_defaultAssistants containsObject:bot]) {
        // already exists
        return NO;
    }
    DIMAddressNameServer *ans = [DIMClientFacebook ans];
    id<MKMID> fixed = [ans getID:@"assistant"];
    if ([fixed isEqual:bot]) {
        [_defaultAssistants insertObject:bot atIndex:0];
    } else {
        [_defaultAssistants addObject:bot];
    }
    return YES;
}

- (BOOL)containsAssistant:(id<MKMID>)bot group:(id<MKMID>)group {
    NSArray<id<MKMID>> *assistants = [self assistantsOfGroup:group];
    return [assistants containsObject:bot];
}

@end

#pragma mark - ANS

static id<DIMAddressNameTable> _ansTable = nil;

@interface ANS : DIMAddressNameServer

@end

@implementation ANS

// Override
- (nullable id<MKMID>)getID:(NSString *)name {
    id<MKMID> ID = [super getID:name];
    if (ID) {
        return ID;
    }
    ID = [_ansTable recordForName:name];
    if (ID) {
        // FIXME: is reserved name?
        [self cacheID:ID withName:name];
    }
    return ID;
}

- (BOOL)saveID:(id<MKMID>)ID withName:(NSString *)alias {
    if (![self cacheID:ID withName:alias]) {
        // username is reserved
        return NO;
    }
    if (alias) {
        return [_ansTable addRecord:ID forName:alias];
    } else {
        return [_ansTable removeRecordForName:alias];
    }
}

@end

@implementation DIMSharedFacebook (ANS)

+ (id<DIMAddressNameTable>)ansTable {
    return _ansTable;
}

+ (void)setANSTable:(id<DIMAddressNameTable>)ansTable {
    _ansTable = ansTable;
}

+ (void)prepare {
    [super prepare];
    ANS *ans = [[ANS alloc] init];
    [DIMClientFacebook setANS:ans];
}

@end
