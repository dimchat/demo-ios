// license: https://mit-license.org
//
//  SeChat : Secure/secret Chat Application
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
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
//  DIMSharedGroupManager.m
//  Sechat
//
//  Created by Albert Moky on 2023/12/16.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import <ObjectKey/ObjectKey.h>

#import "DIMGlobalVariable.h"

#import "DIMSharedGroupManager.h"

@interface DIMSharedGroupManager ()

@property (strong, nonatomic) DIMGroupDelegate *delegate;
@property (strong, nonatomic) DIMGroupManager *manager;
@property (strong, nonatomic) DIMGroupAdminManager *adminManager;
@property (strong, nonatomic) DIMGroupEmitter *emitter;

@end

@implementation DIMSharedGroupManager

OKSingletonImplementations(DIMSharedGroupManager, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        //
    }
    return self;
}

- (DIMCommonFacebook *)facebook {
    DIMGlobalVariable *shared = [DIMGlobalVariable sharedInstance];
    return [shared facebook];
}

- (DIMCommonMessenger *)messenger {
    DIMGlobalVariable *shared = [DIMGlobalVariable sharedInstance];
    return [shared messenger];
}

- (DIMGroupDelegate *)delegate {
    DIMGroupDelegate *ds = _delegate;
    if (!ds) {
        _delegate = ds = [[DIMGroupDelegate alloc] initWithFacebook:self.facebook
                                                          messenger:self.messenger];
    }
    return ds;
}

- (DIMGroupManager *)manager {
    DIMGroupManager *man = _manager;
    if (!man) {
        _manager = man = [[DIMGroupManager alloc] initWithDelegate:self.delegate];
    }
    return man;
}

- (DIMGroupAdminManager *)adminManager {
    DIMGroupAdminManager *man = _adminManager;
    if (!man) {
        _adminManager = man = [[DIMGroupAdminManager alloc] initWithDelegate:self.delegate];
    }
    return man;
}

- (DIMGroupEmitter *)emitter {
    DIMGroupEmitter *em = _emitter;
    if (!em) {
        _emitter = em = [[DIMGroupEmitter alloc] initWithDelegate:self.delegate];
    }
    return em;
}

- (NSString *)buildGroupName:(NSArray<id<MKMID>> *)members {
    return [self.delegate buildGroupNameWithMembers:members];
}

//- (id<MKMBulletin>)bulletinForGroup:(id<MKMID>)gid {
//    return [self.delegate bulletinForID:gid];
//}

//
//  Entity DataSource
//

// Override
- (id<MKMMeta>)metaForID:(id<MKMID>)ID {
    return [self.delegate metaForID:ID];
}

// Override
- (NSArray<id<MKMDocument>> *)documentsForID:(id<MKMID>)ID {
    return [self.delegate documentsForID:ID];
}

//
//  Group DataSource
//

// Override
- (id<MKMID>)founderOfGroup:(id<MKMID>)group {
    return [self.delegate founderOfGroup:group];
}

// Override
- (id<MKMID>)ownerOfGroup:(id<MKMID>)group {
    return [self.delegate ownerOfGroup:group];
}

// Override
- (NSArray<id<MKMID>> *)membersOfGroup:(id<MKMID>)group {
    return [self.delegate membersOfGroup:group];
}

// Override
- (NSArray<id<MKMID>> *)assistantsOfGroup:(id<MKMID>)gid {
    return [self.delegate assistantsOfGroup:gid];
}

- (NSArray<id<MKMID>> *)administratorsForGroup:(id<MKMID>)gid {
    return [self.delegate administratorsOfGroup:gid];
}

- (BOOL)isOwner:(id<MKMID>)uid group:(id<MKMID>)gid {
    return [self.delegate isOwner:uid group:gid];
}

- (BOOL)broadcastDocument:(id<MKMDocument>)doc {
    id<MKMBulletin> bulletin = (id<MKMBulletin>)doc;
    return [self.adminManager broadcastDocument:bulletin];
}

#pragma mark Group Manage

- (id<MKMID>)createGroupWithMembers:(NSArray<id<MKMID>> *)members {
    return [self.manager createGroupWithMembers:members];
}

- (BOOL)updateAdministrators:(NSArray<id<MKMID>> *)newAdmins group:(id<MKMID>)gid {
    return [self.adminManager updateAdministrators:newAdmins group:gid];
}

- (BOOL)resetMembers:(NSArray<id<MKMID>> *)newMembers group:(id<MKMID>)gid {
    return [self.manager resetMembers:newMembers group:gid];
}

- (BOOL)expelMembers:(NSArray<id<MKMID>> *)expelMembers group:(id<MKMID>)gid {
    NSAssert([gid isGroup] && [expelMembers count] > 0, @"params error: %@, %@", gid, expelMembers);
    
    id<MKMUser> user = [self.facebook currentUser];
    if (!user) {
        NSAssert(false, @"failed to get current user");
        return NO;
    }
    id<MKMID> me = [user ID];
    
    DIMGroupDelegate *delegate = [self delegate];
    NSArray<id<MKMID>> *oldMembers = [delegate membersOfGroup:gid];
    
    BOOL isOwner = [delegate isOwner:me group:gid];
    BOOL isAdmin = [delegate isAdministrator:me group:gid];
    
    // 0. check permission
    BOOL canReset = isOwner || isAdmin;
    if (canReset) {
        // You are the owner/admin, then
        // remove the members and 'reset' the group
        NSMutableArray<id<MKMID>> *members = [oldMembers mutableCopy];
        for (id<MKMID> item in expelMembers) {
            [members removeObject:item];
        }
        return [self resetMembers:members group:gid];
    }
    
    // not an admin/owner
    NSAssert(false, @"Cannot expel members from group: %@", gid);
    return NO;
}

- (BOOL)inviteMembers:(NSArray<id<MKMID>> *)newMembers group:(id<MKMID>)gid {
    return [self.manager inviteMembers:newMembers group:gid];
}

- (BOOL)quitGroup:(id<MKMID>)gid {
    return [self.manager quitGroup:gid];
}

#pragma mark Sending group message

- (id<DKDReliableMessage>)sendInstantMessage:(id<DKDInstantMessage>)iMsg
                                    priority:(NSInteger)prior {
    NSAssert([iMsg.content group], @"group message error: %@", iMsg);
    return [self.emitter sendInstantMessage:iMsg priority:prior];
}

@end
