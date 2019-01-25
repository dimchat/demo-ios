//
//  Station.h
//  DIM
//
//  Created by Albert Moky on 2019/1/11.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface Station : DIMStation <NSStreamDelegate, DIMStationDelegate, DIMTransceiverDelegate>

@property (strong, nonatomic) NSString *session;

- (void)handshake;

@end

NS_ASSUME_NONNULL_END
