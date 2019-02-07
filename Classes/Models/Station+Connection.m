//
//  Station+Connection.m
//  DIM
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Station+Connection.h"

@implementation Station (Connection)

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
    if (_inputStream.streamStatus == NSStreamStatusClosed ||
        _inputStream.streamStatus == NSStreamStatusError ||
        
        _outputStream.streamStatus == NSStreamStatusClosed ||
        _outputStream.streamStatus == NSStreamStatusError ||
        [_outputStream hasSpaceAvailable] == NO) {
        
        _state = StationState_Error;
        return NO;
    }
    return YES;
}

- (BOOL)runTask:(Task *)task {
    if (![self isConnected]) {
        NSLog(@"connection lost");
        return NO;
    }
    DKDTransceiverCompletionHandler handler = task.completionHandler;
    NSMutableData *pack = [[NSMutableData alloc] initWithBytes:task.data.bytes length:task.data.length];
    [pack appendBytes:"\n" length:1];
    NSInteger written = [_outputStream write:pack.bytes maxLength:pack.length];
    if (written != pack.length) {
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
    NSLog(@"task done");
    return YES;
}

- (void)run {
    DIMClient *client = [DIMClient sharedInstance];
    DIMUser *user = nil;
    Task *task = nil;
    
    while (_state != StationState_Stopped) {
        
        switch (_state) {
            case StationState_Init: {
                // check user login
                user = client.currentUser;
                if (user) {
                    @try {
                        _state = StationState_Connecting;
                        [self connect];
                    } @catch (NSException *exception) {
                        NSLog(@"failed to connect station (%@:%d)", _host, _port);
                        _state = StationState_Error;
                        sleep(3);
                    } @finally {
                        //
                    }
                } else {
                    // waiting for new user login
                    NSLog(@"[Station] No user login, paused");
                    sleep(3);
                }
            }
                break;
                
            case StationState_Connecting: {
                // waiting for connection
                sleep(1);
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
                // run task
                if (_tasks.count > 0) {
                    task = _tasks.firstObject;
                    BOOL sent = NO;
                    @try {
                        sent = [self runTask:task];
                    } @catch (NSException *exception) {
                        NSLog(@"run task error: %@", exception);
                    } @finally {
                        if (sent) {
                            [_tasks removeObject:task];
                        } else {
                            _state = StationState_Error;
                        }
                    }
                } else {
                    // no task
                    sleep(1);
                }
            }
                break;
                
            case StationState_Error: {
                // reconnect
                [self disconnect];
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


@end
