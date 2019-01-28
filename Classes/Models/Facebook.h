//
//  Facebook.h
//  DIM
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface Facebook : NSObject <MKMAccountDelegate,
                                MKMUserDataSource,
                                MKMUserDelegate,
                                //-
                                MKMGroupDataSource,
                                MKMGroupDelegate,
                                MKMMemberDelegate,
                                MKMChatroomDataSource,
                                //-
                                MKMEntityDataSource,
                                MKMProfileDataSource>

+ (instancetype)sharedInstance;

- (MKMID *)IDWithAddress:(const MKMAddress *)address;

@end

NS_ASSUME_NONNULL_END
