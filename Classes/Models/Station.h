//
//  Station.h
//  DIM
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(UInt8, StationState) {
    StationState_Init,
    StationState_Running,
    StationState_Paused,  // client.currentUser is empty
    StationState_Stopped,
};

@interface Station : DIMStation <NSStreamDelegate, DIMStationDelegate, DIMTransceiverDelegate> {
    
    StationState _state;
    
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    
    NSMutableArray *_tasks;
    
    NSString *_session;
}

- (instancetype)initWithID:(const MKMID *)ID
                 publicKey:(const MKMPublicKey *)PK
                      host:(const NSString *)IP
                      port:(UInt32)port;

- (void)start;
- (void)stop;

- (void)switchUser;

@end

NS_ASSUME_NONNULL_END
