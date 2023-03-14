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
//  DIMSharedSession.m
//  Sechat
//
//  Created by Albert Moky on 2023/3/14.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import <MarsGate/MarsGate.h>

#import "DIMSharedSession.h"

@interface MarsChannel : NIOSocketChannel <STChannel, SGStarDelegate>

@property(nonatomic, weak) MGMars *mars;

@property(nonatomic, strong) id<NIOSocketAddress> remoteAddress;

@property(nonatomic, strong) NSMutableArray<NSData *> *caches;  // received data

@end

@implementation MarsChannel

- (instancetype)init {
    if (self = [super init]) {
        self.mars = nil;
        self.remoteAddress = nil;
        self.caches = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark NIOAbstractInterruptibleChannel

- (BOOL)isOpen {
    return [_mars status] > SGStarStatus_Init;
}

- (BOOL)isAlive {
    return [self isOpen] && ([self isConnected] || [self isBound]);
}

- (void)close {
    [_mars terminate];
}

#pragma mark NIOSelectableChannel

- (nullable NIOSelectableChannel *)configureBlocking:(BOOL)blocking {
    NSLog(@"blocking: %d", blocking);
    return self;
}

- (BOOL)isBlocking {
    //NSAssert(false, @"override me!");
    return NO;
}

#pragma mark NIOSocketChannel

- (BOOL)isBound {
    //NSAssert(false, @"override me!");
    return NO;
}

- (BOOL)isConnected {
    return [_mars status] == SGStarStatus_Connected;
}

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local {
    NSLog(@"bind local: %@", local);
    return self;
}

- (nullable id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote {
    NSLog(@"connect remote: %@", remote);
    return self;
}

- (nullable id<NIOByteChannel>)disconnect {
    [_mars terminate];
    return self;
}


- (nullable id<NIOSocketAddress>)receiveWithBuffer:(NIOByteBuffer *)dst {
    NSData *pack = nil;
    @synchronized (self) {
        if ([_caches count] > 0) {
            pack = [_caches firstObject];
            [_caches removeObjectAtIndex:0];
        }
    }
    if (pack) {
        [dst putData:pack];
        return _remoteAddress;
    }
    return nil;
}


- (NSInteger)sendWithBuffer:(NIOByteBuffer *)src remoteAddress:(id<NIOSocketAddress>)remote {
    // flip to read data
    [src flip];
    NSInteger len = src.remaining;
    NSMutableData *data = [[NSMutableData alloc] initWithLength:len];
    [src getData:data];
    // send data
    [_mars send:data handler:self];
    return data.length;;
}


// Override
- (NSInteger)readWithBuffer:(NIOByteBuffer *)dst {
    NSData *pack = nil;
    @synchronized (self) {
        if ([_caches count] > 0) {
            pack = [_caches firstObject];
            [_caches removeObjectAtIndex:0];
        }
    }
    if (pack) {
        [dst putData:pack];
    }
    return [pack length];
}

// Override
- (NSInteger)writeWithBuffer:(NIOByteBuffer *)src {
    // flip to read data
    [src flip];
    NSInteger len = src.remaining;
    NSMutableData *data = [[NSMutableData alloc] initWithLength:len];
    [src getData:data];
    // send data
    [_mars send:data handler:self];
    return data.length;;
}

// Override
- (id<NIOSocketAddress>)remoteAddress {
    return _remoteAddress;
}

// Override
- (id<NIOSocketAddress>)localAddress {
    NSLog(@"local address");
    return nil;
}

#pragma mark SGStarDelegate

- (NSInteger)star:(id<SGStar>)star onReceive:(NSData *)responseData {
    @synchronized (self) {
        [_caches addObject:responseData];
    }
    return 0;
}

@end

#pragma mark -

@interface MarsHub : STClientHub

@property(nonatomic, strong) MGMars *mars;

@end

@implementation MarsHub

- (NSDictionary *)launchOptions:(id<NIOSocketAddress>)remoteAddress {
    return @{
        @"LongLinkAddress": @"dim.chat",
        @"LongLinkPort": @(remoteAddress.port),
        @"ShortLinkPort": @(remoteAddress.port),
        @"NewDNS": @{
            @"dim.chat": @[
                remoteAddress.host,
            ],
        }
    };
}

- (id<STChannel>)createSocketChannelForRemoteAddress:(id<NIOSocketAddress>)remote
                                        localAddress:(id<NIOSocketAddress>)local {
    NSLog(@"create channel: %@, %@", remote, local);
    MarsChannel *channel = [[MarsChannel alloc] init];
    MGMars *mars = [[MGMars alloc] initWithMessageHandler:channel];
    channel.mars = mars;
    channel.remoteAddress = remote;
    [mars launchWithOptions:[self launchOptions:remote]];
    self.mars = mars;
    return channel;
}

@end

#pragma mark -

@implementation DIMSharedSession

- (STStreamHub *)createHubForRemoteAddress:(id<NIOSocketAddress>)remote
                             socketChannel:(NIOSocketChannel *)sock
                                  delegate:(id<STConnectionDelegate>)gate {
    return [[MarsHub alloc] initWithConnectionDelegate:gate];
}

@end
