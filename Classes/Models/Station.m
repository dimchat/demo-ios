//
//  Station.m
//  DIM
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "Station.h"

@interface Station () {
    
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}

@end

@implementation Station

- (instancetype)initWithID:(const MKMID *)ID
                 publicKey:(const MKMPublicKey *)PK
                      host:(const NSString *)IP
                      port:(UInt32)port {
    if (self = [super initWithID:ID publicKey:PK host:IP port:port]) {
        _inputStream = nil;
        _outputStream = nil;
        _session = nil;
        
        _delegate = self;
        
        [self connectToHost:IP port:port];
    }
    return self;
}

- (void)connectToHost:(const NSString *)host port:(UInt32)port {
    NSLog(@"connecting to %@:%d", host, port);
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    
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

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            break;
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"NSStreamEventHasBytesAvailable");
            
            [self readData];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            
//            [_inputStream close];
//            [_outputStream close];
//
//            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop]
//                                    forMode:NSDefaultRunLoopMode];
//            [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop]
//                                     forMode:NSDefaultRunLoopMode];
//            
//            _inputStream = nil;
//            _outputStream = nil;
            
            break;
            
        default:
            break;
    }
}

- (void)readData {
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

#pragma mark -

- (void)handshake {
    // current user
    DIMUser *user = [DIMClient sharedInstance].currentUser;
    
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
    NSData *data = [rMsg jsonData];
    [self sendPackage:data completionHandler:^(const NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else {
            NSLog(@"send %@ -> %@", command, rMsg);
        }
    }];
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
        NSLog(@"session %@ -> %@", self.session, session);
        self.session = session;
        [self handshake];
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
    if (![_outputStream hasSpaceAvailable]) {
        return NO;
    }
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
        return NO;
    }
    return YES;
}

@end
