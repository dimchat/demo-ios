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
//  DIMSharedProcessor.m
//  DIMP
//
//  Created by Albert Moky on 2020/12/13.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "DIMProcessorFactory.h"
#import "DIMMessageDataSource.h"

#import "DIMSharedProcessor.h"

@implementation DIMSharedProcessor

- (id<DIMContentProcessorCreator>)createContentProcessorCreator {
    return [[SCProcessorCreator alloc] initWithFacebook:self.facebook messenger:self.messenger];
}

- (NSArray<id<DKDInstantMessage>> *)processInstantMessage:(id<DKDInstantMessage>)iMsg
                               withReliableMessageMessage:(id<DKDReliableMessage>)rMsg {
    // call super to process
    NSArray<id<DKDInstantMessage>> *responses = [super processInstantMessage:iMsg
                                                  withReliableMessageMessage:rMsg];
    // save instant/secret message
    DIMMessageDataSource *mds = [DIMMessageDataSource sharedInstance];
    if (![mds saveInstantMessage:iMsg]) {
        // error
        return nil;
    }
    return responses;
}

@end
