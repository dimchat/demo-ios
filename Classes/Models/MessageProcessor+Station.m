//
//  MessageProcessor+Station.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "Facebook+Register.h"

#import "Client.h"

#import "MessageProcessor+Station.h"

@implementation MessageProcessor (Station)

- (void)processHandshakeMessageContent:(DIMMessageContent *)content {
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    DIMHandshakeCommand *cmd;
    cmd = [[DIMHandshakeCommand alloc] initWithDictionary:content];
    DIMHandshakeState state = cmd.state;
    if (state == DIMHandshake_Success) {
        // handshake OK
        NSLog(@"handshake accepted: %@", user);
        NSLog(@"current station: %@", self);
        client.state = DIMTerminalState_Running;
        // post profile
        DIMProfile *profile = MKMProfileForID(user.ID);
        [client postProfile:profile meta:nil];
    } else if (state == DIMHandshake_Again) {
        // update session and handshake again
        NSString *session = cmd.sessionKey;
        NSLog(@"session %@ -> %@", client.session, session);
        client.session = session;
        [client handshake];
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
    Client *client = [Client sharedInstance];
    [client postNotificationName:@"OnlineUsersUpdated" object:self userInfo:info];
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
    Client *client = [Client sharedInstance];
    [client postNotificationName:@"SearchUsersUpdated" object:self userInfo:mDict];
}

@end
