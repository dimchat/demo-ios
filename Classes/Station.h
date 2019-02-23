//
//  Station.h
//  DIMClient
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>
#import <MarsGate/MarsGate.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(UInt8, StationState) {
    StationState_Init,         // (re)set user, (re)connect
    StationState_Connecting,   // connecting to server
    StationState_Connected,    // success to connect server
    StationState_Error,        // failed to connect
    StationState_ShakingHands, // user not login
    StationState_Running,      // user login, sending msg
    StationState_Stopped,
};

@interface Station : DIMStation <DIMTransceiverDelegate, SGStarDelegate> {
    
    StationState _state;
    NSString *_session;
}

@property (nonatomic) StationState state;
@property (strong, nonatomic) NSString *session;

@property (strong, nonatomic) MGMars *starGate;

- (instancetype)initWithID:(const DIMID *)ID
                 publicKey:(const DIMPublicKey *)PK
                      host:(const NSString *)IP
                      port:(UInt32)port;

+ (instancetype)stationWithConfigFile:(NSString *)spConfig;

- (void)start;
- (void)stop;

- (void)pause;
- (void)resume;

@end

//@interface Station : DIMStation <NSStreamDelegate, DIMStationDelegate, DIMTransceiverDelegate> {
//    
//
//    NSInputStream *_inputStream;
//    NSOutputStream *_outputStream;
//    
//    NSMutableArray *_tasks;
//    
//}
//
//@end
//
//#pragma mark -
//
//@interface Task : NSObject
//
//@property (strong, nonatomic) const NSData *data;
//@property (nonatomic) DKDTransceiverCompletionHandler completionHandler;
//
//- (instancetype)initWithData:(const NSData *)data
//           completionHandler:(DKDTransceiverCompletionHandler)handler;
//
//@end

NS_ASSUME_NONNULL_END
