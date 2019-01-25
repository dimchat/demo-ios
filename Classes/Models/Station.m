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

- (void)handshake {
    // current user
    DIMUser *user = [DIMClient sharedInstance].currentUser;
    
    // command 'handshake'
    DIMMessageContent *content;
    content = [[DIMMessageContent alloc] initWithCommand:@"handshake"];
    [content setObject:@"Hello world!" forKey:@"message"];
    if (_session) {
        [content setObject:_session forKey:@"session"];
    }
    
    // send
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    [trans sendMessageContent:content
                         from:user.ID
                           to:_ID
                         time:nil
                     callback:^(const DKDReliableMessage * _Nonnull rMsg, const NSError * _Nullable error) {
                         if (error) {
                             NSLog(@"error: %@", error);
                         } else {
                             NSLog(@"send %@ -> %@", content, rMsg);
                         }
                     }];
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

#pragma mark DIMStationDelegate

- (void)station:(const DIMStation *)station didReceiveData:(const NSData *)data {
    DIMClient *client = [DIMClient sharedInstance];
    Station *server = (Station *)client.currentStation;
    DIMUser *user = client.currentUser;
    
    // trans to instant message
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    DKDInstantMessage *iMsg;
    iMsg = [trans messageFromReceivedPackage:data forUser:user];
    
    // process commands
    DIMMessageContent *content = iMsg.content;
    if (content.type == DIMMessageType_Command) {
        NSString *command = content.command;
        // handshake
        if ([command isEqualToString:@"handshake"]) {
            NSString *message = [content objectForKey:@"message"];
            if ([message isEqualToString:@"DIM!"] ||
                [message isEqualToString:@"OK!"]) {
                // handshake OK
                NSLog(@"handshake accepted");
            } else if ([message isEqualToString:@"DIM?"]) {
                // update session and handshake again
                NSString *session = [content objectForKey:@"session"];
                NSLog(@"session %@ -> %@", server.session, session);
                server.session = session;
                [server handshake];
            } else {
                NSLog(@"handshake rejected: %@", content);
            }
            return;
        }
    }
    
    DIMAmanuensis *clerk = [DIMAmanuensis sharedInstance];
    [clerk saveMessage:iMsg];
    
}

#pragma mark DKDTransceiverDelegate

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
