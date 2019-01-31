//
//  Station.m
//  DIM
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "Station.h"

@interface Task : NSObject

@property (strong, nonatomic) const NSData *data;
@property (nonatomic) DKDTransceiverCompletionHandler completionHandler;

- (instancetype)initWithData:(const NSData *)data
           completionHandler:(DKDTransceiverCompletionHandler)handler;

@end

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

#pragma mark -

@implementation Station

- (instancetype)initWithID:(const MKMID *)ID
                 publicKey:(const MKMPublicKey *)PK
                      host:(const NSString *)IP
                      port:(UInt32)port {
    if (self = [super initWithID:ID publicKey:PK host:IP port:port]) {
        
        _state = StationState_Init;
        
        _inputStream = nil;
        _outputStream = nil;
        
        _tasks = [[NSMutableArray alloc] init];
        
        _session = nil;
        
        _delegate = self;
    }
    return self;
}

- (void)connect {
    
    NSLog(@"connecting to %@:%d", _host, _port);
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)_host, _port, &readStream, &writeStream);
    
//    CFReadStreamSetProperty(readStream,
//                            kCFStreamNetworkServiceType,
//                            kCFStreamNetworkServiceTypeVoIP);
//    CFWriteStreamSetProperty(writeStream,
//                             kCFStreamNetworkServiceType,
//                             kCFStreamNetworkServiceTypeVoIP);
    
    _inputStream = (__bridge NSInputStream *)(readStream);
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    
    [_inputStream setProperty:NSStreamNetworkServiceTypeVoIP
                       forKey:NSStreamNetworkServiceType];
    [_outputStream setProperty:NSStreamNetworkServiceTypeVoIP
                        forKey:NSStreamNetworkServiceType];
    
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                            forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                             forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
}

- (void)disconnect {
    [_inputStream close];
    [_outputStream close];
    
    [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop]
                            forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop]
                             forMode:NSDefaultRunLoopMode];
    
    _inputStream.delegate = nil;
    _outputStream.delegate = nil;
    
    _inputStream = nil;
    _outputStream = nil;
}

- (BOOL)isConnected {
//    if (![_outputStream hasSpaceAvailable]) {
//        [self disconnect];
//        return NO;
//    }
    if (!_inputStream) {
        [self disconnect];
        return NO;
    }
    return YES;
}

- (BOOL)runTask:(Task *)task {
    if (![_outputStream hasSpaceAvailable]) {
        return NO;
    }
    const NSData *data = task.data;
    DKDTransceiverCompletionHandler handler = task.completionHandler;
    
    NSInteger written = [_outputStream write:data.bytes maxLength:data.length];
    if (written != data.length) {
        if (handler) {
            NSDictionary *info = @{
                                   @"message" : @"output stream error",
                                   @"length"  : @(written),
                                   };
            NSError *error;
            error = [[NSError alloc] initWithDomain:NSStreamSOCKSErrorDomain
                                               code:-1
                                           userInfo:info];
            handler(error);
        }
        
        [self disconnect];
        return NO;
    }
    return YES;
}

- (void)run {
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = nil;
    Task *task = nil;
    while (_state != StationState_Stopped) {
        // check user login
        user = client.currentUser;
        if (!user) {
            // waiting for new user login
            NSLog(@"[Station] No user login, paused");
            _state = StationState_Paused;
            sleep(1);
            continue;
        }
        
        // start handshake with new user
        if (_state == StationState_Paused) {
            // try to reconect
            [self disconnect];
            [self connect];
            // handshake
            [self handshakeWithUser:user];
            _state = StationState_Running;
        }
        
        // run task
        if (_tasks.count > 0) {
            task = _tasks.firstObject;
            if ([self runTask:task]) {
                [_tasks removeObject:task];
            }
        } else {
            // no task
            sleep(1);
        }
    }
}

- (void)start {
    _state = StationState_Paused;
    [self performSelectorInBackground:@selector(run) withObject:nil];
}

- (void)stop {
    _state = StationState_Stopped;
}

- (void)switchUser {
    _state = StationState_Paused;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"NSStreamEventOpenCompleted");
        }
            break;
            
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
            
            NSMutableData *mData = [[NSMutableData alloc] initWithCapacity:1024];
            uint8_t buf[1024];
            NSInteger len;
            while ([_inputStream hasBytesAvailable]) {
                len = [_inputStream read:buf maxLength:sizeof(buf)];
                if (len > 0) {
                    [mData appendBytes:(const void *)buf length:len];
                }
            }
            
            if (mData.length > 0) {
                NSAssert(_delegate, @"delegate not set");
                NSString *string = [mData UTF8String];
                NSArray *array = [string componentsSeparatedByString:@"\n"];
                for (string in array) {
                    if (string.length > 0) {
                        [_delegate station:self didReceiveData:[string data]];
                    }
                }
            }
        }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            
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
    [_tasks insertObject:task atIndex:0];
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
    
    DIMMetaCommand *command;
    command = [[DIMMetaCommand alloc] initWithID:ID meta:nil];
    // pack and send
    [trans sendMessageContent:command
                         from:user.ID
                           to:self.ID
                         time:nil
                     callback:^(const DKDReliableMessage *rMsg,
                                const NSError *error) {
                         if (error) {
                             NSLog(@"error: %@", error);
                         } else {
                             NSLog(@"send %@ -> %@", command, rMsg);
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
