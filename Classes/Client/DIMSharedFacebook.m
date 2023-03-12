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
#import "DIMSocialNetworkDatabase.h"

#import "DIMMessenger+Extension.h"

#import "DIMSharedFacebook.h"

@interface ANS : DIMAddressNameServer {
    
    DIMSocialNetworkDatabase *_database;
}

- (instancetype)initWithDatabase:(DIMSocialNetworkDatabase *)db;

@end

@implementation ANS

- (instancetype)initWithDatabase:(DIMSocialNetworkDatabase *)db {
    if (self = [super init]) {
        _database = db;
    }
    return self;
}

- (nullable id<MKMID>)getID:(NSString *)username {
    id<MKMID> ID = [_database ansRecordForName:username];
    if (ID) {
        return ID;
    }
    return [super getID:username];
}

- (NSArray<NSString *> *)getNames:(id<MKMID>)ID {
    NSArray<NSString *> *names = [_database namesWithANSRecord:ID.string];
    if (names) {
        return names;
    }
    return [super getNames:ID];
}

- (BOOL)saveID:(id<MKMID>)ID withName:(NSString *)username {
    if (![self cacheID:ID withName:username]) {
        // username is reserved
        return NO;
    }
    return [_database saveANSRecord:ID forName:username];
}

@end

#pragma mark -

#define PROFILE_EXPIRES  1800  // document expires (30 minutes)
#define PROFILE_EXPIRES_KEY @"expires"

@interface DIMSharedFacebook () {
    
    // user db
    DIMSocialNetworkDatabase *_database;
    
    // ANS
    id<DIMAddressNameService> _ans;
    
    // local userss
    NSMutableArray<id<MKMUser>> *_allUsers;
}

@end

@implementation DIMSharedFacebook

OKSingletonImplementations(DIMSharedFacebook, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        
        // user db
        _database = [[DIMSocialNetworkDatabase alloc] init];
        
        // ANS
        _ans = [[ANS alloc] initWithDatabase:_database];
        
        // local userss
        _allUsers = nil;
    }
    return self;
}

- (nullable NSArray<id<MKMUser>> *)localUsers {
    if (!_allUsers) {
        _allUsers = [[NSMutableArray alloc] init];
        NSArray<id<MKMID>> *list = [_database allUsers];
        id<MKMUser> user;
        for (id<MKMID> item in list) {
            user = [self userWithID:item];
            NSAssert(user, @"failed to get local user: %@", item);
            [_allUsers addObject:user];
        }
    }
    return _allUsers;
}

- (void)setCurrentUser:(id<MKMUser>)user {
    if (!user) {
        NSAssert(false, @"current user cannot be empty");
        return;
    }
    NSArray<id<MKMID>> *list = [_database allUsers];
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:(list.count + 1)];
    [mArray addObject:user.ID];
    for (id<MKMID> item in list) {
        if ([mArray containsObject:item]) {
            continue;
        }
        [mArray addObject:item];
    }
    [_database saveUsers:mArray];
    _allUsers = nil;
}

- (BOOL)saveUsers:(NSArray<id<MKMID>> *)list {
    return [_database saveUsers:list];
}

- (BOOL)isWaitingMeta:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // broadcast ID doesn't contain meta
        return NO;
    }
    return [self metaForID:ID] == nil;
}

- (nullable id<MKMUser>)createUser:(id<MKMID>)ID {
    if ([self isWaitingMeta:ID]) {
        return nil;
    }
    return [super createUser:ID];
}

- (nullable id<MKMGroup>)createGroup:(id<MKMID>)ID {
    if ([self isWaitingMeta:ID]) {
        return nil;
    }
    return [super createGroup:ID];
}

#pragma mark Storage

- (BOOL)saveMeta:(id<MKMMeta>)meta forID:(id<MKMID>)ID {
    if (![_database saveMeta:meta forID:ID]) {
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

- (nullable id<MKMMeta>)metaForID:(id<MKMID>)ID {
    if (MKMIDIsBroadcast(ID)) {
        // broadcast ID has no meta
        return nil;
    }
    // try from database
    id<MKMMeta> meta = [_database metaForID:ID];
    if (!meta) {
        // query from DIM network
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger queryMetaForID:ID];
    }
    return meta;
}

- (BOOL)saveDocument:(id<MKMDocument>)doc {
    if (![self checkDocument:doc]) {
        return NO;
    }
    [doc removeObjectForKey:PROFILE_EXPIRES_KEY];
    if (![_database saveDocument:doc]) {
        return NO;
    }
    NSDictionary *info = [doc dictionary];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNotificationName_DocumentUpdated object:self userInfo:info];
    return YES;
}

- (nullable id<MKMDocument>)documentForID:(id<MKMID>)ID type:(nullable NSString *)type {
    if (MKMIDIsBroadcast(ID)) {
        // broadcast ID has no document
        return nil;
    }
    // try from database
    id<MKMDocument> doc = [_database documentForID:ID type:type];
    if (!doc || [self isExpiredDocument:doc]) {
        if (doc) {
            // update EXPIRES value
            NSDate *now = [[NSDate alloc] init];
            NSTimeInterval timestamp = [now timeIntervalSince1970];
            [doc setObject:@(timestamp + PROFILE_EXPIRES) forKey:PROFILE_EXPIRES_KEY];
        }
        // query from DIM network
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger queryDocumentForID:ID];
    }
    return doc;
}

- (BOOL)isExpiredDocument:(id<MKMDocument>)doc {
    NSDate *now = [[NSDate alloc] init];
    NSTimeInterval timestamp = [now timeIntervalSince1970];
    NSNumber *expires = [doc objectForKey:PROFILE_EXPIRES_KEY];
    if (!expires) {
        // set expired time
        [doc setObject:@(timestamp + PROFILE_EXPIRES) forKey:PROFILE_EXPIRES_KEY];
        return NO;
    }
    return timestamp > [expires doubleValue];
}

- (BOOL)savePrivateKey:(id<MKMPrivateKey>)key type:(NSString *)type user:(id<MKMID>)ID {
    return [_database savePrivateKey:key type:type forID:ID];
}

- (NSArray<id<MKMDecryptKey>> *)privateKeysForDecryption:(id<MKMID>)user {
    return [_database privateKeysForDecryption:user];
}

- (id<MKMSignKey>)privateKeyForSignature:(id<MKMID>)user {
    return [_database privateKeyForSignature:user];
}

- (id<MKMSignKey>)privateKeyForVisaSignature:(id<MKMID>)user {
    return [_database privateKeyForVisaSignature:user];
}

- (BOOL)saveContacts:(NSArray<id<MKMID>> *)contacts user:(id<MKMID>)ID {
//    if (![self cacheContacts:contacts user:ID]) {
//        return NO;
//    }
    BOOL OK = [_database saveContacts:contacts user:ID];
    if (OK) {
        NSDictionary *info = @{@"ID": ID};
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:kNotificationName_ContactsUpdated
                          object:self userInfo:info];
    }
    return OK;
}

- (nullable NSArray<id<MKMID>> *)contactsOfUser:(id<MKMID>)ID {
    return [_database contactsOfUser:ID];
    //return [super contactsOfUser:ID];
}

- (nullable NSArray<id<MKMID>> *)membersOfGroup:(id<MKMID>)group {
    NSArray<id<MKMID>> *members = [_database membersOfGroup:group];
    if (members.count > 0) {
        return members;
    }
    return [super membersOfGroup:group];
}

- (BOOL)saveMembers:(NSArray<id<MKMID>> *)members group:(id<MKMID>)ID {
    BOOL OK = [_database saveMembers:members group:ID];
    if (OK) {
        NSDictionary *info = @{@"group": ID};
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:kNotificationName_GroupMembersUpdated
                          object:self userInfo:info];
    }
    return OK;
}

- (nullable NSArray<id<MKMID>> *)assistantsOfGroup:(id<MKMID>)group {
    return @[
        // dev
        MKMIDParse(@"assistant@2PpB6iscuBjA15oTjAsiswoX9qis5V3c1Dq"),
        // desktop.dim.chat
        MKMIDParse(@"assistant@4WBSiDzg9cpZGPqFrQ4bHcq4U5z9QAQLHS"),
    ];
    //return [super assistantsOfGroup:group];
}

@end
