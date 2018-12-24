//
//  Facebook.h
//  DIM
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Search Number String

 @param code - check code
 @return "123-456-7890"
 */
NSString *search_number(UInt32 code);

/**
 Account Title for Conversation

 @param account - account
 @return "Name (search number)"
 */
NSString *account_title(const MKMAccount *account);

/**
 Group Title for Conversation

 @param group - group
 @return "Name (members count)"
 */
NSString *group_title(const MKMGroup *group);

@interface Facebook : NSObject <MKMUserDataSource,
                                MKMUserDelegate,
                                MKMContactDelegate,
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
