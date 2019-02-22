//
//  Station.m
//  DIM
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"

#import "MessageProcessor+Station.h"

#import "Client.h"
#import "Station+Handler.h"
#import "Station+Connection.h"

#import "Station.h"

@implementation Station

- (instancetype)initWithID:(const DIMID *)ID
                 publicKey:(const DIMPublicKey *)PK
                      host:(const NSString *)IP
                      port:(UInt32)port {
    if (self = [super initWithID:ID publicKey:PK host:IP port:port]) {
        
        _state = StationState_Init;
        
        _session = nil;
        
        _starGate = [[MGMars alloc] initWithMessageHandler:self];
        
        _delegate = [MessageProcessor sharedInstance];
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
    [Client sharedInstance].currentStation = server;
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

- (void)run {
    Client *client = [Client sharedInstance];
    DIMUser *user = nil;
    
    while (_state != StationState_Stopped) {
        
        switch (_state) {
            case StationState_Init: {
                // check user login
                user = client.currentUser;
                if (user) {
                    _state = StationState_Connecting;
                } else {
                    // waiting for new user login
                    NSLog(@"[Station] No user login, paused");
                    sleep(3);
                }
            }
                break;
                
            case StationState_Connecting: {
                if (_starGate.isConnected) {
                    sleep(1);
                    _state = StationState_Connected;
                } else {
                    // waiting for connection
                    sleep(1);
                }
            }
                break;
                
            case StationState_Connected: {
                _state = StationState_ShakingHands;
                [self handshakeWithUser:user];
            }
                break;
                
            case StationState_ShakingHands: {
                // waiting for shacking hands
                sleep(1);
            }
                break;
                
            case StationState_Running: {
//                // run task
//                if (_tasks.count > 0) {
//                    task = _tasks.firstObject;
//                    BOOL sent = NO;
//                    @try {
//                        sent = [self runTask:task];
//                    } @catch (NSException *exception) {
//                        NSLog(@"run task error: %@", exception);
//                    } @finally {
//                        if (sent) {
//                            [_tasks removeObject:task];
//                        } else {
//                            _state = StationState_Error;
//                        }
//                    }
//                } else {
//                    // no task
//                    sleep(1);
//                }
            }
                break;
                
            case StationState_Error: {
//                // reconnect
//                [self disconnect];
                _state = StationState_Init;
                sleep(2);
            }
                break;
                
            case StationState_Stopped: {
                // terminate
            }
                break;
                
            default: {
                NSAssert(false, @"unknown status: %d", _state);
            }
                break;
                
        } /* EOF switch (_state) */
        
    } /* EOF while (_state != StationState_Stopped) */
}

#pragma mark DKDTransceiverDelegate

- (BOOL)sendPackage:(const NSData *)data completionHandler:(nullable DKDTransceiverCompletionHandler)handler {
    NSLog(@"sending data len: %ld", data.length);
    // TODO: send data
    NSInteger res = [_starGate send:data];
    
    if (handler) {
        NSError *error;
        if (res < 0) {
            error = [[NSError alloc] initWithDomain:NSNetServicesErrorDomain
                                               code:res
                                           userInfo:nil];
        } else {
            error = nil;
        }
        handler(error);
    }
    
    return res == 0;
}

#pragma mark SGStarDelegate

- (NSInteger)onReceive:(const NSData *)responseData {
    NSLog(@"response data len: %ld", responseData.length);
    [[MessageProcessor sharedInstance] station:self didReceivePackage:responseData];
    return 0;
}

@end

//@interface Station () {
//    
//    NSMutableData *_inputData;
//}
//
//@end
//
//@implementation Station
//
//#pragma mark - NSStreamDelegate
//
//- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
//    switch (eventCode) {
//        case NSStreamEventOpenCompleted: {
//            NSLog(@"NSStreamEventOpenCompleted: %@", aStream);
//        }
//            break;
//            
//        case NSStreamEventHasBytesAvailable: {
//            NSLog(@"NSStreamEventHasBytesAvailable: %@", aStream);
//            
//            if (_inputData) {
//                NSLog(@"last not finished data: %@", [_inputData UTF8String]);
//            } else {
//                _inputData = [[NSMutableData alloc] initWithCapacity:1024];
//            }
//            uint8_t buf[1024];
//            NSInteger len;
//            while ([_inputStream hasBytesAvailable]) {
//                len = [_inputStream read:buf maxLength:sizeof(buf)];
//                if (len > 0) {
//                    [_inputData appendBytes:(const void *)buf length:len];
//                }
//            }
//            
//            if (_inputData.length > 0) {
//                NSAssert(_delegate, @"delegate not set");
//                NSString *string = [_inputData UTF8String];
//                _inputData = nil;
//                NSArray *array = [string componentsSeparatedByString:@"\n"];
//                NSUInteger count = [array count];
//                for (NSUInteger index = 0; index < count; ++index) {
//                    string = [array objectAtIndex:index];
//                    if (string.length == 0) {
//                        continue;
//                    }
//                    @try {
//                        [_delegate station:self didReceivePackage:[string data]];
//                    } @catch (NSException *exception) {
//                        NSLog(@"**** JsON error!");
//                        if (index == count - 1) {
//                            // not finished data, push back for next input
//                            _inputData = [[NSMutableData alloc] initWithData:[string data]];
//                            NSLog(@"not finished data: %@", [_inputData UTF8String]);
//                        }
//                    }
//                }
//            }
//        }
//            break;
//            
//        case NSStreamEventHasSpaceAvailable: {
//            NSLog(@"NSStreamEventHasSpaceAvailable: %@", aStream);
//            if (_state == StationState_Connecting &&
//                aStream == _outputStream) {
//                NSLog(@"connected");
//                _state = StationState_Connected;
//            }
//        }
//            break;
//            
//        case NSStreamEventErrorOccurred: {
//            NSLog(@"NSStreamEventErrorOccurred: %@", aStream);
//            [self disconnect];
//            _state = StationState_Error;
//        }
//            break;
//            
//        case NSStreamEventEndEncountered: {
//            NSLog(@"NSStreamEventEndEncountered: %@", aStream);
//            [self disconnect];
//            _state = StationState_Init;
//        }
//            break;
//            
//        default:
//            break;
//    }
//}
//
//#pragma mark - DKDTransceiverDelegate
//
//- (BOOL)sendPackage:(const NSData *)data completionHandler:(DKDTransceiverCompletionHandler)handler {
//    // push the task to waiting queue
//    Task *task = [[Task alloc] initWithData:data completionHandler:handler];
//    [_tasks addObject:task];
//    return YES;
//}
//
//@end
//
//#pragma mark -
//
//@implementation Task
//
//- (instancetype)initWithData:(const NSData *)data
//           completionHandler:(DKDTransceiverCompletionHandler)handler {
//    if (self = [self init]) {
//        self.data = data;
//        self.completionHandler = handler;
//    }
//    return self;
//}
//
//@end
