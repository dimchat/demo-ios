//
//  Station.m
//  DIM
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "Station+Handler.h"
#import "Station+Connection.h"

#import "Station.h"

@interface Station () {
    
    NSMutableData *_inputData;
}

@end

@implementation Station

- (instancetype)initWithID:(const DIMID *)ID
                 publicKey:(const DIMPublicKey *)PK
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

#pragma mark DIMStationDelegate

- (void)station:(const DIMStation *)server didReceiveData:(const NSData *)data {
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
        } else if ([command isEqualToString:@"profile"]) {
            // query profile response
            return [self processProfileMessageContent:content];
        } else if ([command isEqualToString:@"users"]) {
            // query online users response
            return [self processOnlineUsersMessageContent:content];
        } else if ([command isEqualToString:@"search"]) {
            // search users response
            return [self processSearchUsersMessageContent:content];
        } else {
            NSLog(@"!!! unknown command: %@, sender: %@, message content: %@",
                  command, sender, content);
            return ;
        }
    }
    
    if (MKMNetwork_IsStation(sender.type)) {
        NSLog(@"*** message from station: %@", content);
        return ;
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
