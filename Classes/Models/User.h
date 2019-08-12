//
//  User.h
//  DIMClient
//
//  Created by Albert Moky on 2019/2/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Search Number String
 *
 * @param code - check code
 * @return "123-456-7890"
 */
NSString *search_number(UInt32 code);

/**
 *  User Title for Conversation
 *
 * @param user - user
 * @return "Name (search number)"
 */
NSString *user_title(DIMUser *user);

/**
 *  Group Title for Conversation
 *
 * @param group - group
 * @return "Name (members count)"
 */
NSString *group_title(DIMGroup *group);

/**
 *  Readable name for Entity ID
 *
 * @param ID - entity ID
 * @return "..."
 */
NSString *readable_name(DIMID *ID);

/**
 *  Check Username Valid
 *
 * @param username - format: ^[A-Za-z0-9_-\.]+$
 * @return YES on valid
 */
BOOL check_username(NSString *username);

@interface DIMLocalUser (Config)

+ (nullable instancetype)userWithConfigFile:(NSString *)config;

@end

NS_ASSUME_NONNULL_END
