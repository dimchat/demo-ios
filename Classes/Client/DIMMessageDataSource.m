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
//  DIMMessageDataSource.m
//  DIMP
//
//  Created by Albert Moky on 2020/12/23.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "DIMGlobalVariable.h"

#import "DIMConstants.h"

#import "DIMStorageCommand.h"
#import "DIMSearchCommand.h"

#import "DIMAmanuensis.h"

#import "DIMKeyStore.h"
#import "DIMSharedMessenger.h"
#import "DIMMessageDataSource.h"

@interface DIMMessageDataSource () {
    
    NSMutableDictionary<id<MKMID>, NSMutableArray<id<DKDReliableMessage>> *> *incomingMessages;
    NSMutableDictionary<id<MKMID>, NSMutableArray<id<DKDInstantMessage>> *> *outgoingMessages;
}

@end

@implementation DIMMessageDataSource

OKSingletonImplementations(DIMMessageDataSource, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        
        incomingMessages = [[NSMutableDictionary alloc] init];
        outgoingMessages = [[NSMutableDictionary alloc] init];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(onEntityUpdated:) name:kNotificationName_MetaSaved object:nil];
        [nc addObserver:self selector:@selector(onEntityUpdated:) name:kNotificationName_DocumentUpdated object:nil];
    }
    return self;
}

- (void)onEntityUpdated:(NSNotification *)notification {
    id ID = [notification.userInfo objectForKey:@"ID"];
    NSAssert(ID, @"ID not found: %@", notification.userInfo);
    ID = MKMIDParse(ID);
    
    DIMFacebook *facebook = [DIMGlobal facebook];
    if (MKMIDIsUser(ID)) {
        // check user
        if (![facebook publicKeyForEncryption:ID]) {
            NSLog(@"user not ready yet: %@", ID);
            return;
        }
    }
    DIMSharedMessenger *messenger = [DIMGlobal messenger];
    
    // processing incoming messages
    NSMutableArray<id<DKDReliableMessage>> *incomings = [incomingMessages objectForKey:ID];
    if (incomings) {
        // remove from pool first
        [incomingMessages removeObjectForKey:ID];
        
        // process them now
        NSArray<id<DKDReliableMessage>> *responses;
        for (id<DKDReliableMessage> item in incomings) {
            responses = [messenger processReliableMessage:item];
            if ([responses count] == 0) {
                continue;
            }
            for (id<DKDReliableMessage> res in responses) {
                [messenger sendReliableMessage:res priority:1];
            }
        }
    }
    
    // processing outgoing messages
    NSMutableArray<id<DKDInstantMessage>> *outgoing = [outgoingMessages objectForKey:ID];
    if (outgoing) {
        // remove from pool
        [outgoingMessages removeObjectForKey:ID];
        
        // send them out
        for (id<DKDInstantMessage> item in outgoing) {
            [messenger sendInstantMessage:item priority:1];
        }
    }
}

#pragma mark - DIMMessengerDataSource

- (BOOL)saveInstantMessage:(id<DKDInstantMessage>)iMsg {
    id<DKDContent> content = iMsg.content;
    // TODO: check message type
    //       only save normal message and group commands
    //       ignore 'Handshake', ...
    //       return true to allow responding
    
    if ([content isKindOfClass:[DIMHandshakeCommand class]]) {
        // handshake command will be processed by CPUs
        // no need to save handshake command here
        return YES;
    }
    if ([content isKindOfClass:[DIMMetaCommand class]]) {
        // meta & document command will be checked and saved by CPUs
        // no need to save meta & document command here
        return YES;
    }
    if ([content isKindOfClass:[DIMMuteCommand class]] ||
        [content isKindOfClass:[DIMBlockCommand class]]) {
        // TODO: create CPUs for mute & block command
        // no need to save mute & block command here
        return YES;
    }
    if ([content isKindOfClass:[DIMSearchCommand class]]) {
        // search result will be parsed by CPUs
        // no need to save search command here
        return YES;
    }
    if ([content isKindOfClass:[DIMForwardContent class]]) {
        // forward content will be parsed, if secret message decrypted, save it
        // no need to save forward content itself
        return YES;
    }
    
    if ([content conformsToProtocol:@protocol(DKDInviteGroupCommand)]) {
        // send keys again
        id<MKMID> me = iMsg.envelope.receiver;
        id<MKMID> group = content.group;
        DIMKeyStore *keyStore = [DIMKeyStore sharedInstance];
        id<MKMSymmetricKey> key = [keyStore cipherKeyWithSender:me receiver:group generate:NO];
        [key removeObjectForKey:@"reused"];
        NSLog(@"key (%@ => %@): %@", me, group, key);
    }
    if ([content isKindOfClass:[DIMQueryGroupCommand class]]) {
        // FIXME: same query command sent to different members?
        return YES;
    }
    
    if ([content isKindOfClass:[DIMStorageCommand class]]) {
        return YES;
    }
    
    //Check whether is a command
    if ([content isKindOfClass:[DIMLoginCommand class]]) {
        return YES;
    }
    
    if([content conformsToProtocol:@protocol(DKDCommand)]){
        id<DKDCommand> command = (id<DKDCommand>)content;
        if([command.cmd isEqualToString:@"broadcast"]){
            NSLog(@"It is a broadcast command, skip : %@", content);
            return YES;
        }
    }
    
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    
    if ([content isKindOfClass:[DIMReceiptCommand class]]) {
        return [clerk saveReceipt:iMsg];
    } else {
        return [clerk saveInstantMessage:iMsg];
    }
}

- (BOOL)suspendReliableMessage:(id<DKDReliableMessage>)rMsg {
    id<MKMID> waiting = [rMsg objectForKey:@"waiting"];
    if (waiting) {
        [rMsg removeObjectForKey:@"waiting"];
    } else {
        waiting = rMsg.group;
        if (!waiting) {
            waiting = rMsg.sender;
        }
    }
    NSMutableArray<id<DKDReliableMessage>> *list = [incomingMessages objectForKey:waiting];
    if (!list) {
        list = [[NSMutableArray alloc] init];
        [incomingMessages setObject:list forKey:waiting];
    }
    [list addObject:rMsg];
    return YES;
}

- (BOOL)suspendInstantMessage:(id<DKDInstantMessage>)iMsg {
    id<MKMID> waiting = [iMsg objectForKey:@"waiting"];
    if (waiting) {
        [iMsg removeObjectForKey:@"waiting"];
    } else {
        waiting = iMsg.group;
        if (!waiting) {
            waiting = iMsg.receiver;
        }
    }
    NSMutableArray<id<DKDInstantMessage>> *list = [outgoingMessages objectForKey:waiting];
    if (!list) {
        list = [[NSMutableArray alloc] init];
        [outgoingMessages setObject:list forKey:waiting];
    }
    [list addObject:iMsg];
    return YES;
}

@end
