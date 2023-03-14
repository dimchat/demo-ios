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
//  DIMSharedMessenger.h
//  DIMP
//
//  Created by Albert Moky on 2020/12/13.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import <DIMP/DIMP.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMSharedMessenger : DIMClientMessenger

@property(nonatomic, readonly) id<MKMUser> currentUser;

@property(nonatomic, readonly) id<MKMStation> currentStation;

@end

@interface DIMSharedMessenger (Send)

/**
 *  Pack and send command to station
 *
 * @param content - command sending to the neighbor station
 * @param prior - task priority, smaller is faster
 * @return true on success
 */
- (BOOL)sendCommand:(id<DKDCommand>)content priority:(NSInteger)prior;

/**
 *  Pack and broadcast content to everyone
 *
 * @param content - message content
 */
- (BOOL)broadcastContent:(id<DKDContent>)content;

/**
 *  Broadcast visa to all contacts
 *
 * @param doc - user visa document
 * @return YES on success
 */
- (BOOL)broadcastVisa:(id<MKMVisa>)doc;

/**
 *  Post document & meta to station
 *
 * @param doc - entity document
 * @param meta - enntity meta
 * @return YES on success
 */
- (BOOL)postDocument:(id<MKMDocument>)doc withMeta:(id<MKMMeta>)meta;

/**
 *  Encrypt and post contacts list to station
 *
 * @param contacts - ID list
 * @return YES on success
 */
- (BOOL)postContacts:(NSArray<id<MKMID>> *)contacts;

@end

@interface DIMSharedMessenger (Query)

/**
 *  Query contacts while login from a new device
 *
 * @return YES on success
 */
- (BOOL)queryContacts;

/**
 *  Query mute-list from station
 *
 * @return YES on success
 */
- (BOOL)queryMuteList;

/**
 *  Query block-list from station
 *
 * @return YES on success
 */
- (BOOL)queryBlockList;

/**
 *  Query group member list from any member
 *
 * @param group - group ID
 * @param member - member ID
 * @return YES on success
 */
- (BOOL)queryGroupForID:(id<MKMID>)group fromMember:(id<MKMID>)member;
- (BOOL)queryGroupForID:(id<MKMID>)group fromMembers:(NSArray<id<MKMID>> *)members;

@end

@interface DIMSharedMessenger (Factories)

+ (void)prepare;

@end

NS_ASSUME_NONNULL_END
