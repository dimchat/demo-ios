//
//  Station.m
//  DIM
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "Station+Connection.h"

#import "Station.h"

@interface Station () {
    
    NSMutableData *_inputData;
}

@end

@implementation Station

- (instancetype)initWithID:(const MKMID *)ID
                 publicKey:(const MKMPublicKey *)PK
                      host:(const NSString *)IP
                      port:(UInt32)port {
    if (self = [super initWithID:ID publicKey:PK host:IP port:port]) {
        
        _state = StationState_Init;
        
        _inputStream = nil;
        _outputStream = nil;
        
        _inputData = nil;
        
        _tasks = [[NSMutableArray alloc] init];
        
        _session = nil;
        
        _delegate = self;
    }
    return self;
}

+ (instancetype)stationWithConfigFile:(NSString *)spConfig {
    NSDictionary *gsp = [NSDictionary dictionaryWithContentsOfFile:spConfig];
    NSArray *stations = [gsp objectForKey:@"stations"];
    
    // choose the fast station
    NSDictionary *station = stations.firstObject;
    
    // save meta for server ID
    DIMID *ID = [station objectForKey:@"ID"];
    ID = [DIMID IDWithID:ID];
    DIMMeta *meta = [station objectForKey:@"meta"];
    meta = [DIMMeta metaWithMeta:meta];
    [[DIMBarrack sharedInstance] setMeta:meta forID:ID];
    
    // connect server
    Station *server = [[Station alloc] initWithDictionary:station];
    [DIMClient sharedInstance].currentStation = server;
    [DIMTransceiver sharedInstance].delegate = server;
    return server;
}

- (void)start {
    _state = StationState_Init;
    [self performSelectorInBackground:@selector(run) withObject:nil];
}

- (void)stop {
    _state = StationState_Stopped;
}

- (void)switchUser {
    _state = StationState_Init;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"NSStreamEventOpenCompleted: %@", aStream);
        }
            break;
            
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable: %@", aStream);
            
            if (_inputData) {
                NSLog(@"last not finished data: %@", [_inputData UTF8String]);
            } else {
                _inputData = [[NSMutableData alloc] initWithCapacity:1024];
            }
            uint8_t buf[1024];
            NSInteger len;
            while ([_inputStream hasBytesAvailable]) {
                len = [_inputStream read:buf maxLength:sizeof(buf)];
                if (len > 0) {
                    [_inputData appendBytes:(const void *)buf length:len];
                }
            }
            
            if (_inputData.length > 0) {
                NSAssert(_delegate, @"delegate not set");
                NSString *string = [_inputData UTF8String];
                _inputData = nil;
                NSArray *array = [string componentsSeparatedByString:@"\n"];
                NSUInteger count = [array count];
                for (NSUInteger index = 0; index < count; ++index) {
                    string = [array objectAtIndex:index];
                    if (string.length == 0) {
                        continue;
                    }
                    @try {
                        [_delegate station:self didReceiveData:[string data]];
                    } @catch (NSException *exception) {
                        NSLog(@"**** JsON error!");
                        if (index == count - 1) {
                            // not finished data, push back for next input
                            _inputData = [[NSMutableData alloc] initWithData:[string data]];
                            NSLog(@"not finished data: %@", [_inputData UTF8String]);
                            break;
                        }
                    }
                }
            }
        }
            break;
            
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"NSStreamEventHasSpaceAvailable: %@", aStream);
            if (_state == StationState_Connecting &&
                aStream == _outputStream) {
                NSLog(@"connected");
                _state = StationState_Connected;
            }
        }
            break;
            
        case NSStreamEventErrorOccurred: {
            NSLog(@"NSStreamEventErrorOccurred: %@", aStream);
            [self disconnect];
            _state = StationState_Error;
        }
            break;
            
        case NSStreamEventEndEncountered: {
            NSLog(@"NSStreamEventEndEncountered: %@", aStream);
            [self disconnect];
            _state = StationState_Init;
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -

- (void)handshakeWithUser:(DIMUser *)user {
    
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

- (void)queryMetaForID:(DIMID *)ID {
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    
    DIMMetaCommand *cmd;
    cmd = [[DIMMetaCommand alloc] initWithID:ID meta:nil];
    // pack and send
    [trans sendMessageContent:cmd
                         from:user.ID
                           to:self.ID
                         time:nil
                     callback:^(const DKDReliableMessage *rMsg,
                                const NSError *error) {
                         if (error) {
                             NSLog(@"error: %@", error);
                         } else {
                             NSLog(@"send %@ -> %@", cmd, rMsg);
                         }
                     }];
}

- (void)processMetaMessageContent:(DIMMessageContent *)content {
    DIMMetaCommand *cmd;
    cmd = [[DIMMetaCommand alloc] initWithDictionary:content];
    if ([cmd.meta matchID:cmd.ID]) {
        NSLog(@"got new meta for %@", cmd.ID);
        DIMBarrack *facebook = [DIMBarrack sharedInstance];
        [facebook saveMeta:cmd.meta forEntityID:cmd.ID];
    }
}

- (void)processOnlineUsersMessageContent:(DIMMessageContent *)content {
    NSArray *users = [content objectForKey:@"users"];
    if ([users count] > 0) {
        NSString *dir = NSTemporaryDirectory();
        NSString *path = [dir stringByAppendingPathComponent:@"online_users.plist"];
        [users writeToFile:path atomically:YES];
        // notice
        NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
        [dc postNotificationName:@"OnlineUsersUpdated" object:users];
    }
}

- (void)searchUsersWithKeywords:(NSString *)keywords {
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    
    DIMCommand *cmd = [[DIMCommand alloc] initWithCommand:@"search"];
    [cmd setObject:keywords forKey:@"keywords"];
    // pack and send
    [trans sendMessageContent:cmd
                         from:user.ID
                           to:self.ID
                         time:nil
                     callback:^(const DKDReliableMessage *rMsg,
                                const NSError *error) {
                         if (error) {
                             NSLog(@"error: %@", error);
                         } else {
                             NSLog(@"send %@ -> %@", cmd, rMsg);
                         }
                     }];
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

#pragma mark DIMStationDelegate

- (void)station:(const DIMStation *)station didReceiveData:(const NSData *)data {
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = client.currentUser;
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    
    // decode
    NSString *json = [data UTF8String];
    DIMReliableMessage *rMsg;
    rMsg = [[DKDReliableMessage alloc] initWithJSONString:json];
    
    // check sender
    DIMID *sender = rMsg.envelope.sender;
    DIMMeta *meta = MKMMetaForID(sender);
    if (!meta) {
        meta = rMsg.meta;
        if (!meta) {
            NSLog(@"meta for %@ not found, query from the network...", sender);
            return [self queryMetaForID:sender];
        }
    }
    
    // trans to instant message
    DKDInstantMessage *iMsg;
    iMsg = [trans verifyAndDecryptMessage:rMsg forUser:user];
    
    // process commands
    DIMMessageContent *content = iMsg.content;
    if (content.type == DIMMessageType_Command) {
        NSString *command = content.command;
        if ([command isEqualToString:@"handshake"]) {
            // handshake
            return [self processHandshakeMessageContent:content];
        } else if ([command isEqualToString:@"meta"]) {
            // query meta response
            return [self processMetaMessageContent:content];
        } else if ([command isEqualToString:@"users"]) {
            // query online users response
            return [self processOnlineUsersMessageContent:content];
        } else if ([command isEqualToString:@"search"]) {
            // search users response
            return [self processSearchUsersMessageContent:content];
        }
    }
    
    // normal message, let the clerk to deliver it
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    [clerk saveMessage:iMsg];
    
}

#pragma mark - DKDTransceiverDelegate

- (BOOL)sendPackage:(const NSData *)data completionHandler:(DKDTransceiverCompletionHandler)handler {
    // push the task to waiting queue
    Task *task = [[Task alloc] initWithData:data completionHandler:handler];
    [_tasks addObject:task];
    return YES;
}

@end

#pragma mark -

@implementation Task

- (instancetype)initWithData:(const NSData *)data
           completionHandler:(DKDTransceiverCompletionHandler)handler {
    if (self = [self init]) {
        self.data = data;
        self.completionHandler = handler;
    }
    return self;
}

@end
