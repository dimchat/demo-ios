// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
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
//  DIMSharedDatabase.m
//  Sechat
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMSharedDatabase.h"

static inline NSString *private_label(NSString *type, id<MKMID> ID) {
    NSString *address = [ID.address string];
    if ([type length] == 0) {
        return address;
    }
    return [NSString stringWithFormat:@"%@:%@", type, address];
}

static inline BOOL private_save(id<MKMPrivateKey> key, NSString *type, id<MKMID> ID) {
    NSString *label = private_label(type, ID);
    return MKMPrivateKeySave(label, key);
}

static inline id<MKMPrivateKey> private_load(NSString *type, id<MKMID> ID) {
    NSString *label = private_label(type, ID);
    return MKMPrivateKeyLoad(label);
}

@implementation DIMSharedDatabase

- (instancetype)init {
    if (self = [super init]) {
        _metaTable     = [[DIMMetaTable alloc] init];
        _documentTable = [[DIMDocumentTable alloc] init];
        _userTable     = [[DIMUserTable alloc] init];
        _contactTable  = [[DIMContactTable alloc] init];
        _groupTable    = [[DIMGroupTable alloc] init];
        _msgKeyTable   = [DIMKeyStore sharedInstance];
    }
    return self;
}

//
//  User Table
//

// Override
- (NSArray<id<MKMID>> *)localUsers {
    return [_userTable localUsers];
}

// Override
- (BOOL)saveLocalUsers:(NSArray<id<MKMID>> *)users {
    return [_userTable saveLocalUsers:users];
}

// Override
- (NSArray<id<MKMID>> *)contactsOfUser:(id<MKMID>)user {
    return [_contactTable contactsOfUser:user];
}

// Override
- (BOOL)saveContacts:(NSArray<id<MKMID>> *)contacts user:(id<MKMID>)user {
    return [_contactTable saveContacts:contacts user:user];
}

// Override
- (id<MKMID>)currentUser {
    return [_userTable currentUser];
}

// Override
- (void)setCurrentUser:(id<MKMID>)currentUser {
    [_userTable setCurrentUser:currentUser];
}

// Override
- (BOOL)addUser:(id<MKMID>)user {
    return [_userTable addUser:user];
}

// Override
- (BOOL)removeUser:(id<MKMID>)user {
    return [_userTable removeUser:user];;
}

// Override
- (BOOL)addContact:(id<MKMID>)contact user:(id<MKMID>)user {
    BOOL OK = [_contactTable addContact:contact user:user];
    if (OK) {
        // TODO: post notification 'ContactsUpdated'
    }
    return OK;
}

// Override
- (BOOL)removeContact:(id<MKMID>)contact user:(id<MKMID>)user {
    BOOL OK = [_contactTable removeContact:contact user:user];
    if (OK) {
        // TODO: post notification 'ContactsUpdated'
    }
    return OK;
}

//
//  Group Table
//

// Override
- (nullable id<MKMID>)founderOfGroup:(id<MKMID>)group {
    id<MKMID> founder = [_groupTable founderOfGroup:group];
    if (founder) {
        return founder;
    }
    // check each member's public key with group meta
    id<MKMMeta> gMeta = [self metaForID:group];
    NSArray<id<MKMID>> *members = [_groupTable membersOfGroup:group];
    id<MKMMeta> meta;
    for (id<MKMID> member in members) {
        // if the user's public key matches with the group's meta,
        // it means this meta was generate by the user's private key
        meta = [self metaForID:member];
        if ([gMeta matchPublicKey:meta.publicKey]) {
            return member;
        }
    }
    return nil;
}

// Override
- (nullable id<MKMID>)ownerOfGroup:(id<MKMID>)group {
    id<MKMID> owner = [_groupTable ownerOfGroup:group];
    if (owner) {
        return owner;
    }
    if ([group type] == MKMNetwork_Polylogue) {
        // Polylogue's owner is its founder
        return [self founderOfGroup:group];
    }
    return nil;
}

// Override
- (NSArray<id<MKMID>> *)membersOfGroup:(id<MKMID>)group {
    return [_groupTable membersOfGroup:group];
}

// Override
- (BOOL)saveMembers:(NSArray<id<MKMID>> *)members group:(id<MKMID>)gid {
    bool OK = [_groupTable saveMembers:members group:gid];
    if (OK) {
        // TODO: post notification 'MembersUpdated'
    }
    return OK;
}

// Override
- (NSArray<id<MKMID>> *)assistantsOfGroup:(id<MKMID>)group {
    return [_groupTable assistantsOfGroup:group];
}

// Override
- (BOOL)saveAssistants:(NSArray<id<MKMID>> *)bots group:(id<MKMID>)gid {
    return [_groupTable saveAssistants:bots group:gid];
}

// Override
- (NSArray<id<MKMID>> *)administratorsOfGroup:(id<MKMID>)group {
    return [_groupTable administratorsOfGroup:group];
}

// Override
- (BOOL)saveAdministrators:(NSArray<id<MKMID>> *)admins group:(id<MKMID>)gid {
    return [_groupTable saveAdministrators:admins group:gid];
}

// Override
- (BOOL)addMember:(id<MKMID>)member group:(id<MKMID>)group {
    BOOL OK = [_groupTable addMember:member group:group];
    if (OK) {
        // TODO: post notification 'MembersUpdated'
    }
    return OK;
}

- (BOOL)removeMember:(id<MKMID>)member group:(id<MKMID>)group {
    BOOL OK = [_groupTable removeMember:member group:group];
    if (OK) {
        // TODO: post notification 'MembersUpdated'
    }
    return OK;
}

- (BOOL)removeGroup:(id<MKMID>)group {
    BOOL OK = [_groupTable removeGroup:group];
    if (OK) {
        // TODO: post notification 'GroupRemoved'
    }
    return OK;
}

//
//  Group History Table
//

// Override
- (BOOL)saveGroupHistory:(id<DKDGroupCommand>)content
             withMessage:(id<DKDReliableMessage>)rMsg
                   group:(id<MKMID>)gid {
    return NO;
}

// Override
- (NSArray<DIMHistoryCmdMsg *> *)historiesOfGroup:(id<MKMID>)group {
    return nil;
}

// Override
- (DIMResetCmdMsg *)resetCommandMessageForGroup:(id<MKMID>)group {
    return nil;
}

// Override
- (BOOL)clearMemberHistoriesOfGroup:(id<MKMID>)group {
    return NO;
}

// Override
- (BOOL)clearAdminHistoriesOfGroup:(id<MKMID>)group {
    return NO;
}

//
//  Account DBI
//

// Override
- (BOOL)savePrivateKey:(id<MKMPrivateKey>)key
              withType:(NSString *)type
               forUser:(id<MKMID>)user {
    // TODO: support multi private keys
    return private_save(key, type, user);
}

// Override
- (id<MKMPrivateKey>)privateKeyForSignature:(id<MKMID>)user {
    // TODO: support multi private keys
    return [self privateKeyForVisaSignature:user];
}

// Override
- (id<MKMPrivateKey>)privateKeyForVisaSignature:(id<MKMID>)user {
    id<MKMPrivateKey> key;
    // get private key paired with meta.key
    key = private_load(DIMPrivateKeyType_Meta, user);
    if (!key) {
        // get private key paired with meta.key
        key = private_load(nil, user);
    }
    return key;
}

// Override
- (NSArray<id<MKMDecryptKey>> *)privateKeysForDecryption:(id<MKMID>)user {
    NSMutableArray *mArray = [[NSMutableArray alloc] init];
    id<MKMPrivateKey> key;
    // 1. get private key paired with visa.key
    key = private_load(DIMPrivateKeyType_Visa, user);
    if (key) {
        [mArray addObject:key];
    }
    // get private key paired with meta.key
    key = private_load(DIMPrivateKeyType_Meta, user);
    if ([key conformsToProtocol:@protocol(MKMDecryptKey)]) {
        [mArray addObject:key];
    }
    // get private key paired with meta.key
    key = private_load(nil, user);
    if ([key conformsToProtocol:@protocol(MKMDecryptKey)]) {
        [mArray addObject:key];
    }
    return mArray;
}

// Override
- (nullable id<MKMMeta>)metaForID:(id<MKMID>)entity {
    return [_metaTable metaForID:entity];
}

// Override
- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)entity {
    BOOL OK;
    if ([meta matchIdentifier:entity]) {
        OK = [_metaTable saveMeta:meta forID:entity];
    } else {
        NSAssert(false, @"meta not match: %@ => %@", entity, meta);
        return NO;
    }
    if (OK) {
        // TODO: post notification 'MetaSaved'
    }
    return OK;
}

// Override
- (id<MKMDocument>)documentForID:(id<MKMID>)entity withType:(nullable NSString *)type {
    return [_documentTable documentForID:entity withType:type];
}

// Override
- (NSArray<id<MKMDocument>> *)documentsForID:(id<MKMID>)entity {
    return [_documentTable documentsForID:entity];
}

// Override
- (BOOL)saveDocument:(id<MKMDocument>)doc {
    id<MKMID> ID = [doc ID];
    id<MKMMeta> meta = [self metaForID:ID];
    NSAssert(meta, @"meta not exists: %@", ID);
    BOOL OK;
    if ([doc isValid] || [doc verify:meta.publicKey]) {
        OK = [_documentTable saveDocument:doc];
    } else {
        NSAssert(false, @"document error: %@", doc);
        return NO;
    }
    if (OK) {
        // TODO: post notification 'DocumentUpdated'
    }
    return OK;
}

//
//  Message DBI
//

// Override
- (nullable id<MKMSymmetricKey>)cipherKeyFrom:(id<MKMID>)sender
                                           to:(id<MKMID>)receiver
                                     generate:(BOOL)create {
    return [_msgKeyTable cipherKeyFrom:sender to:receiver generate:create];
}

// Override
- (void)cacheCipherKey:(id<MKMSymmetricKey>)key
                  from:(id<MKMID>)sender
                    to:(id<MKMID>)receiver {
    [_msgKeyTable cacheCipherKey:key from:sender to:receiver];
}

// Override
- (NSDictionary *)cipherKeysForGroup:(id<MKMID>)gid from:(id<MKMID>)sender {
    return nil;
}

// Override
- (BOOL)saveCipherKeys:(NSDictionary *)keys forGroup:(id<MKMID>)gid from:(id<MKMID>)sender {
    return NO;
}

//// Override
//- (DIMReliableMessageResult *)reliableMessageForReceiver:(id<MKMID>)receiver
//                                                   range:(NSRange)range {
//    // TODO: get messages waiting to send out
//    return nil;
//}
//
//// Override
//- (BOOL)cacheReliableMessage:(id<DKDReliableMessage>)rMsg
//                 forReceiver:(id<MKMID>)receiver {
//    // TODO: cache message for sending out
//    return NO;
//}
//
//// Override
//- (BOOL)removeReliableMessage:(id<DKDReliableMessage>)rMsg
//                  forReceiver:(id<MKMID>)receiver {
//    // TODO: remove message sent
//    return NO;
//}

//
//  Session DBI
//

// Override
- (OKPair<id<DKDLoginCommand>,id<DKDReliableMessage>> *)loginCommandMessageForID:(id<MKMID>)user {
    // TODO: login table
    return nil;
}

// Override
- (BOOL)saveLoginCommand:(id<DKDLoginCommand>)cmd withMessage:(id<DKDReliableMessage>)msg forID:(id<MKMID>)user {
    // TODO: login table
    return NO;
}

// Override
- (NSArray<DIMProviderInfo *> *)allProviders {
    // TODO: provider table
    return nil;
}

// Override
- (BOOL)addProvider:(id<MKMID>)PID chosen:(NSInteger)order {
    // TODO: provider table
    return NO;
}

// Override
- (BOOL)updateProvider:(id<MKMID>)PID chosen:(NSInteger)order {
    // TODO: provider table
    return NO;
}

// Override
- (BOOL)removeProvider:(id<MKMID>)PID {
    // TODO: provider table
    return NO;
}

// Override
- (NSArray<DIMStationInfo *> *)allStations:(id<MKMID>)PID {
    // TODO: station table
    return nil;
}

// Override
- (BOOL)addStation:(id<MKMID>)SID
            chosen:(NSInteger)order
              host:(NSString *)IP
              port:(UInt16)port
          provider:(id<MKMID>)PID {
    // TODO: station table
    return nil;
}

// Override
- (BOOL)updateStation:(id<MKMID>)SID
               chosen:(NSInteger)order
                 host:(NSString *)IP
                 port:(UInt16)port
             provider:(id<MKMID>)PID {
    // TODO: station table
    return NO;
}

// Override
- (BOOL)removeStationWithHost:(NSString *)IP
                         port:(UInt16)port
                     provider:(id<MKMID>)PID {
    // TODO: station table
    return NO;
}

// Override
- (BOOL)removeAllStations:(id<MKMID>)PID {
    // TODO: station table
    return NO;
}

@end
