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
//  DIMSharedGroupManager.h
//  Sechat
//
//  Created by Albert Moky on 2023/12/16.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  This is for sending group message, or managing group members
 */
@interface DIMSharedGroupManager : NSObject <MKMGroupDataSource>

@property (weak, nonatomic, nullable) DIMCommonFacebook *facebook;
@property (weak, nonatomic, nullable) DIMCommonMessenger *messenger;

@property (strong, nonatomic, readonly) DIMGroupDelegate *delegate;
@property (strong, nonatomic, readonly) DIMGroupManager *manager;
@property (strong, nonatomic, readonly) DIMGroupAdminManager *adminManager;
@property (strong, nonatomic, readonly) DIMGroupEmitter *emitter;

+ (instancetype)sharedInstance;

- (NSString *)buildGroupName:(NSArray<id<MKMID>> *)members;

- (id<MKMBulletin>)bulletinForGroup:(id<MKMID>)gid;

- (NSArray<id<MKMID>> *)administratorsForGroup:(id<MKMID>)gid;

- (BOOL)isOwner:(id<MKMID>)uid group:(id<MKMID>)gid;

- (BOOL)broadcastDocument:(id<MKMDocument>)doc;

/**
 *  Create new group with members
 *
 * @param members - new group members
 * @return true on success
 */
- (id<MKMID>)createGroup:(NSArray<id<MKMID>> *)members;

/**
 *  Update 'administrators' in bulletin document
 *
 * @param newAdmins - new administrator ID list
 * @return true on success
 */
- (BOOL)updateAdministrators:(NSArray<id<MKMID>> *)newAdmins group:(id<MKMID>)gid;

/**
 *  Reset group members
 *
 * @param newMembers - new member ID list
 * @return true on success
 */
- (BOOL)resetGroupMembers:(NSArray<id<MKMID>> *)newMembers group:(id<MKMID>)gid;

/**
 *  Expel members from this group
 *  (only group owner/assistant can do this)
 *
 * @param expelMembers - members to be removed
 * @return true on success
 */
- (BOOL)expelGroupMembers:(NSArray<id<MKMID>> *)expelMembers group:(id<MKMID>)gid;

/**
 *  Invite new members to this group
 *  (only existed member/assistant can do this)
 *
 * @param newMembers - new members ID list
 * @return true on success
 */
- (BOOL)inviteGroupMembers:(NSArray<id<MKMID>> *)newMembers group:(id<MKMID>)gid;

/**
 *  Quit from this group
 *  (only group member can do this)
 *
 * @return true on success
 */
- (BOOL)quitGroup:(id<MKMID>)gid;

- (id<DKDReliableMessage>)sendInstantMessage:(id<DKDInstantMessage>)iMsg
                                    priority:(NSInteger)prior;

@end

NS_ASSUME_NONNULL_END
