//
//  Station+Connection.h
//  DIM
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Station.h"

NS_ASSUME_NONNULL_BEGIN

@interface Station (Connection)

- (void)connect;
- (void)disconnect;

- (BOOL)runTask:(Task *)task;

- (void)run;

@end

NS_ASSUME_NONNULL_END
