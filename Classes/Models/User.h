//
//  User.h
//  DIMClient
//
//  Created by Albert Moky on 2019/2/4.
//  Copyright © 2019 DIM Group. All rights reserved.
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
NSString *account_title(const DIMAccount *account);

/**
 Group Title for Conversation
 
 @param group - group
 @return "Name (members count)"
 */
NSString *group_title(const DIMGroup *group);

/**
 Readable name for Entity ID
 
 @param ID - entity ID
 @return "..."
 */
NSString *readable_name(const DIMID *ID);

/**
 Check Username Valid
 
 @param username - format: ^[A-Za-z0-9_-\.]+$
 @return YES on valid
 */
BOOL check_username(const NSString *username);

@interface DIMUser (Config)

+ (instancetype)userWithConfigFile:(NSString *)config;

@end

NS_ASSUME_NONNULL_END
