//
//  Station+Handler.m
//  DIM
//
//  Created by Albert Moky on 2019/2/17.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "Facebook+Register.h"

#import "Client.h"
#import "Station+Connection.h"

#import "Station+Handler.h"

@implementation Station (Handler)


- (void)sendContent:(DKDMessageContent *)content to:(MKMID *)receiver {
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    if (!user) {
        NSLog(@"not login yet");
        return ;
    }
    DKDTransceiverCallback callback;
    callback = ^(const DKDReliableMessage *rMsg,
                 const NSError *error) {
        if (error) {
            NSLog(@"send content error: %@", error);
        } else {
            NSLog(@"send content %@ -> %@", content, rMsg);
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
    NSAssert([msg.envelope.sender isEqual:[Client sharedInstance].currentUser.ID], @"sender error: %@", msg);
    [self sendContent:msg.content to:msg.envelope.receiver];
}

- (void)sendCommand:(DIMCommand *)cmd {
    [self sendContent:cmd to:_ID];
}

@end

@implementation Station (Command)

- (void)login:(DIMUser *)user {
    Client *client = [Client sharedInstance];
    client.currentUser = user;
    
    // switch state for re-login
    _state = StationState_Init;
    
    Facebook *facebook = [Facebook sharedInstance];
    [facebook reloadContactsWithUser:user];
    
    [client postNotificationName:@"ContactsUpdated"];
}

- (void)handshakeWithUser:(const DIMUser *)user {
    // 1. create command 'handshake'
    DIMHandshakeCommand *command;
    command = [[DIMHandshakeCommand alloc] initWithSessionKey:_session];
    
    [self sendCommand:command];
    
//    // 2. make instant message
//    DKDInstantMessage *iMsg;
//    iMsg = [[DKDInstantMessage alloc] initWithContent:command
//                                               sender:user.ID
//                                             receiver:_ID
//                                                 time:nil];
//
//    // 3. pack and attach meta info
//    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
//    DKDReliableMessage *rMsg = [trans encryptAndSignMessage:iMsg];
//    rMsg.meta = MKMMetaForID(user.ID);
//
//    // 4. send out
//    DKDTransceiverCompletionHandler handler;
//    handler = ^(const NSError *error) {
//        if (error) {
//            NSLog(@"handshake error: %@", error);
//        } else {
//            NSLog(@"handshake send %@", command);
//        }
//    };
//    //    Task *task = [[Task alloc] initWithData:[rMsg jsonData]
//    //                          completionHandler:handler];
//    //    // run it immediately
//    //    [self runTask:task];
//    [self sendPackage:[rMsg jsonData] completionHandler:handler];
}

- (void)postProfile:(DIMProfile *)profile meta:(nullable DIMMeta *)meta {
    if (!profile) {
        return ;
    }
    Client *client = [Client sharedInstance];
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
