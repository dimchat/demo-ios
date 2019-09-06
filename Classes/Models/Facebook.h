//
//  Facebook.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kNotificationName_ContactsUpdated;

@interface Facebook : DIMDatabase

+ (instancetype)sharedInstance;

- (nullable DIMID *)IDWithAddress:(DIMAddress *)address;

- (void)addStation:(DIMID *)stationID provider:(DIMServiceProvider *)sp;

@end

NS_ASSUME_NONNULL_END
