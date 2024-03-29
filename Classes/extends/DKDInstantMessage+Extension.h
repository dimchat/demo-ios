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
//  DKDInstantMessage+Extension.h
//  DIMP
//
//  Created by Albert Moky on 2019/10/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(UInt8, DIMMessageState) {
    DIMMessageState_Init = 0,
    DIMMessageState_Normal = DIMMessageState_Init,
    
    DIMMessageState_Waiting,
    DIMMessageState_Sending,   // sending to station
    DIMMessageState_Accepted,  // station accepted, delivering
    
    DIMMessageState_Delivering = DIMMessageState_Accepted,
    DIMMessageState_Delivered, // delivered to receiver (station said)
    DIMMessageState_Arrived,   // the receiver's client feedback
    DIMMessageState_Read,      // the receiver's client feedback
    
    DIMMessageState_Error = -1, // failed to send
};

@interface DIMContent (State)

@property (nonatomic) DIMMessageState state;

@end

NS_ASSUME_NONNULL_END
