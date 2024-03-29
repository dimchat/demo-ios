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
//  DIMSearchCommand.h
//  DIMP
//
//  Created by Albert Moky on 2019/11/30.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

#define DIMCommand_Search      @"search"
#define DIMCommand_OnlineUsers @"users"

/*
 *  Command message: {
 *      type : 0x88,
 *      sn   : 123,
 *
 *      command  : "search",        // or "users"
 *      keywords : "{keywords}",    // keyword string
 *
 *      start    : 0,
 *      limit    : 20,
 *
 *      station  : "{STATION_ID}",  // station ID
 *      users    : ["{ID}"]         // user ID list
 *  }
 */
@protocol DKDSearchCommand <DKDCommand>

@property(nonatomic, strong, readonly, nullable) NSString *keywords;
@property(nonatomic, strong, readonly, nullable) NSArray<id<MKMID>> *users;

@property(nonatomic, strong, nullable) id<MKMID> station;

@property(nonatomic, assign) NSInteger start;
@property(nonatomic, assign) NSInteger limit;

@end

@interface DIMSearchCommand : DIMCommand <DKDSearchCommand>

- (instancetype)initWithKeywords:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
