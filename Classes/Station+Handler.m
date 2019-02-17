//
//  Station+Handler.m
//  DIM
//
//  Created by Albert Moky on 2019/2/17.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "Facebook+Register.h"
#import "Station+Connection.h"

#import "Station+Handler.h"

@implementation Station (Handler)

- (void)processHandshakeMessageContent:(DIMMessageContent *)content {
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    
    DIMHandshakeCommand *cmd;
    cmd = [[DIMHandshakeCommand alloc] initWithDictionary:content];
    DIMHandshakeState state = cmd.state;
    if (state == DIMHandshake_Success) {
        // handshake OK
        NSLog(@"handshake accepted: %@", user);
        NSLog(@"current station: %@", self);
        _state = StationState_Running;
        // post profile
        DIMProfile *profile = MKMProfileForID(user.ID);
        [self postProfile:profile meta:nil];
    } else if (state == DIMHandshake_Again) {
        // update session and handshake again
        NSString *session = cmd.sessionKey;
        NSLog(@"session %@ -> %@", _session, session);
        _session = session;
        [self handshakeWithUser:user];
    } else {
        NSLog(@"handshake rejected: %@", content);
    }
}

- (void)processMetaMessageContent:(DIMMessageContent *)content {
    DIMMetaCommand *cmd;
    cmd = [[DIMMetaCommand alloc] initWithDictionary:content];
    // check meta
    DIMMeta *meta = cmd.meta;
    if ([meta matchID:cmd.ID]) {
        NSLog(@"got new meta for %@", cmd.ID);
        DIMBarrack *barrack = [DIMBarrack sharedInstance];
        [barrack saveMeta:cmd.meta forEntityID:cmd.ID];
    }
}

- (void)processProfileMessageContent:(DIMMessageContent *)content {
    DIMProfileCommand *cmd;
    cmd = [[DIMProfileCommand alloc] initWithDictionary:content];
    // check meta
    DIMMeta *meta = cmd.meta;
    if ([meta matchID:cmd.ID]) {
        NSLog(@"got new meta for %@", cmd.ID);
        DIMBarrack *barrack = [DIMBarrack sharedInstance];
        [barrack saveMeta:cmd.meta forEntityID:cmd.ID];
    }
    // check profile
    DIMProfile *profile = cmd.profile;
    if ([profile.ID isEqual:cmd.ID]) {
        NSLog(@"got new profile for %@", cmd.ID);
        Facebook *facebook = [Facebook sharedInstance];
        [facebook saveProfile:profile forID:cmd.ID];
    }
}

- (void)processOnlineUsersMessageContent:(DIMMessageContent *)content {
    NSArray *users = [content objectForKey:@"users"];
    NSDictionary *info = @{@"users": users};
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc postNotificationName:@"OnlineUsersUpdated" object:info];
}

- (void)processSearchUsersMessageContent:(DIMMessageContent *)content {
    NSArray *users = [content objectForKey:@"users"];
    NSDictionary *results = [content objectForKey:@"results"];
    NSMutableDictionary *mDict = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (users) {
        [mDict setObject:users forKey:@"users"];
    }
    if (results) {
        [mDict setObject:results forKey:@"results"];
    }
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc postNotificationName:@"SearchUsersUpdated" object:mDict];
}

@end

#pragma mark -

@implementation Station (Message)

- (void)sendContent:(DKDMessageContent *)content to:(MKMID *)receiver {
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    if (!user) {
        NSLog(@"not login yet");
        return ;
    }
    DKDTransceiverCallback callback;
    callback = ^(const DKDReliableMessage *rMsg,
                 const NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else {
            NSLog(@"send %@ -> %@", content, rMsg);
        }
    };
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    [trans sendMessageContent:content
                         from:user.ID
                           to:receiver
                         time:nil
                     callback:callback];
}

- (void)sendMessage:(DKDInstantMessage *)msg {
    NSAssert([msg.envelope.sender isEqual:[DIMClient sharedInstance].currentUser.ID], @"sender error: %@", msg);
    [self sendContent:msg.content to:msg.envelope.receiver];
}

- (void)sendCommand:(DIMCommand *)cmd {
    [self sendContent:cmd to:self.ID];
}

@end

@implementation Station (Command)

- (void)login:(DIMUser *)user {
    DIMClient *client = [DIMClient sharedInstance];
    client.currentUser = user;
    
    // switch state for re-login
    _state = StationState_Init;
    
    Facebook *facebook = [Facebook sharedInstance];
    [facebook reloadContactsWithUser:user];
    
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc postNotificationName:@"ContactsUpdated" object:nil];
}

- (void)handshakeWithUser:(const DIMUser *)user {
    
    // 1. create command 'handshake'
    DIMHandshakeCommand *command;
    command = [[DIMHandshakeCommand alloc] initWithSessionKey:_session];
    
    // 2. make instant message
    DKDInstantMessage *iMsg;
    iMsg = [[DKDInstantMessage alloc] initWithContent:command
                                               sender:user.ID
                                             receiver:self.ID
                                                 time:nil];
    
    // 3. pack and attach meta info
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    DKDReliableMessage *rMsg = [trans encryptAndSignMessage:iMsg];
    rMsg.meta = MKMMetaForID(user.ID);
    
    // 4. send out
    DKDTransceiverCompletionHandler handler;
    handler = ^(const NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else {
            NSLog(@"send %@ -> %@", command, rMsg);
        }
    };
    Task *task = [[Task alloc] initWithData:[rMsg jsonData]
                          completionHandler:handler];
    // run it immediately
    [self runTask:task];
}

- (void)postProfile:(DIMProfile *)profile meta:(nullable DIMMeta *)meta {
    if (!profile) {
        return ;
    }
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    
    if (![profile.ID isEqual:user.ID]) {
        NSAssert(false, @"profile ID not match");
        return ;
    }
    
    DIMProfileCommand *cmd;
    cmd = [[DIMProfileCommand alloc] initWithID:user.ID
                                           meta:meta
                                     privateKey:user.privateKey
                                        profile:profile];
    [self sendCommand:cmd];
}

- (void)queryMetaForID:(const DIMID *)ID {
    DIMMetaCommand *cmd;
    cmd = [[DIMMetaCommand alloc] initWithID:ID
                                        meta:nil];
    [self sendCommand:cmd];
}

- (void)queryProfileForID:(const DIMID *)ID {
    DIMProfileCommand *cmd;
    cmd = [[DIMProfileCommand alloc] initWithID:ID
                                           meta:nil
                                        profile:nil
                                      signature:nil];
    [self sendCommand:cmd];
}

- (void)queryOnlineUsers {
    DIMCommand *cmd;
    cmd = [[DIMCommand alloc] initWithCommand:@"users"];
    [self sendCommand:cmd];
}

- (void)searchUsersWithKeywords:(const NSString *)keywords {
    DIMCommand *cmd = [[DIMCommand alloc] initWithCommand:@"search"];
    [cmd setObject:keywords forKey:@"keywords"];
    [self sendCommand:cmd];
}

@end
