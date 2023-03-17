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

#import "DIMConstants.h"

#import "DIMSharedSession.h"

@interface MarsChannel : NIOSocketChannel <STChannel, SGStarDelegate>

@property(nonatomic, strong) MGMars *mars;

@property(nonatomic, strong) id<NIOSocketAddress> remoteAddress;

@property(nonatomic, strong) NSMutableArray<NSData *> *caches;  // received data

@property(nonatomic, readonly) NSUInteger available;

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

- (NSUInteger)available {
    @synchronized (self) {
        if ([self.caches count] > 0) {
            NSData *first = [self.caches firstObject];
            return [first length];
        }
    }
    return 0;
}

- (void)setMars:(MGMars *)mars {
    MGMars *old = _mars;
    if (old) {
        NSLog(@"%@ terminating: %@", self, old);
        [old terminate];
    }
    _mars = mars;
}

#pragma mark NIOAbstractInterruptibleChannel

- (BOOL)isOpen {
    return [_mars status] > SGStarStatus_Init;
}

- (BOOL)isAlive {
    return [self isOpen] && ([self isConnected] || [self isBound]);
}

- (void)close {
    NSLog(@"closing channel");
    self.mars = nil;
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
    return [_mars status] > SGStarStatus_Init;
}

- (BOOL)isConnected {
    return [_mars status] == SGStarStatus_Connected;
}

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local {
    NSLog(@"bind local: %@", local);
    return self;
}

- (nullable id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote {
    NSLog(@"%@, create Mars to connect remote: %@", self, remote);
    MGMars *mars = [[MGMars alloc] initWithMessageHandler:self];
    [mars launchWithOptions:[self launchOptions:remote]];
    self.mars = mars;
    self.remoteAddress = remote;
    return self;
}

- (nullable id<NIOByteChannel>)disconnect {
    NSLog(@"disconnecting channel");
    self.mars = nil;
    return self;
}

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

- (nullable id<NIOSocketAddress>)receiveWithBuffer:(NIOByteBuffer *)dst {
    NSData *pack = nil;
    @synchronized (self) {
        if ([_caches count] > 0) {
            pack = [_caches firstObject];
            [_caches removeObjectAtIndex:0];
        }
    }
    if (pack) {
        NSLog(@"---- receiveWithBuffer: %lu byte(s), remote: %@", [pack length], _remoteAddress);
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
    NSLog(@"---- sendWithBuffer: %lu byte(s) => %@", [data length], remote);
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
        NSLog(@"---- readWithBuffer: %lu byte(s)", [pack length]);
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
    NSLog(@"---- writeWithBuffer: %lu byte(s)", [data length]);
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
    NSUInteger len = [responseData length];
    if (len <= 4) {
        // TODO: respond 'PONG' when received 'PING'
        NSLog(@"star: onReceive: [%@]", MKMUTF8Decode(responseData));
        return 0;
    } else {
        NSLog(@"star: onReceive: %lu byte(s)", len);
    }
    @synchronized (self) {
        [_caches addObject:responseData];
    }
    return 0;
}

- (void)star:(id<SGStar>)star onConnectionStatusChanged:(SGStarStatus)status {
    NSLog(@"star: onConnectionStatusChanged: %d", status);
    if (status == SGStarStatus_Error) {
        NSLog(@"connection error, closing...");
        [self disconnect];
    }
}

- (void)star:(id<SGStar>)star onFinishSend:(NSData *)requestData
   withError:(NSError *)error {
    NSUInteger len = [requestData length];
    if (len == 4) {
        NSLog(@"star: onFinishSend: [%@], error: %@", MKMUTF8Decode(requestData), error);
    } else {
        NSLog(@"star: onFinishSend: %lu byte(s), error: %@", len, error);
    }
}

@end

#pragma mark -

@interface MarsHub : STClientHub

@property(atomic, weak) MarsChannel *channel;

@end

@implementation MarsHub

- (instancetype)initWithConnectionDelegate:(id<STConnectionDelegate>)delegate {
    if (self = [super initWithConnectionDelegate:delegate]) {
        self.channel = nil;
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(onSessionStateChanged:)
                   name:kNotificationName_ServerStateChanged object:nil];
    }
    return self;
}

- (void)onSessionStateChanged:(NSNotification *)notification {
    NSString *name = [notification name];
    NSDictionary *info = notification.userInfo;
    if ([name isEqualToString:kNotificationName_ServerStateChanged]) {
        NSNumber *state = [info objectForKey:@"stateIndex"];
        NSUInteger index = [state unsignedIntegerValue];
        if (index == DIMSessionStateOrderError) {
            NSLog(@">>> Network error!");
            MarsChannel *sock = self.channel;
            if (sock) {
                NSLog(@"mars isOpen: %d", [sock isOpen]);
                id<NIOSocketAddress> remote = [sock remoteAddress];
                id<NIOSocketAddress> local = [sock localAddress];
                id<STConnection> conn = [self connectionWithRemoteAddress:remote
                                                             localAddress:local];
                if ([conn isOpen]) {
                    NSLog(@"closing connection: %@", conn);
                    [conn close];
                }
                if ([sock isOpen]) {
                    NSLog(@"closing mars: %@", sock);
                    [sock close];
                }
                self.channel = nil;
            }
        }
    }
}

- (id<STChannel>)createSocketChannelForRemoteAddress:(id<NIOSocketAddress>)remote
                                        localAddress:(id<NIOSocketAddress>)local {
    MarsChannel *channel = self.channel;
    if ([channel isOpen]) {
        if ([channel.remoteAddress isEqual:remote]) {
            NSLog(@"reuse channel: %@ => %@", remote, channel);
            return channel;
        }
        // TODO: only one channel?
        [channel close];
    }
    NSLog(@"create channel: %@, %@", remote, local);
    channel = [[MarsChannel alloc] init];
    if (local) {
        [channel bindLocalAddress:local];
    }
    NSAssert(remote, @"remote address empty");
    [channel connectRemoteAddress:remote];
    self.channel = channel;
    return channel;
}

- (NSUInteger)availableInChannel:(id<STChannel>)channel {
    return [(MarsChannel *)channel available];
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
