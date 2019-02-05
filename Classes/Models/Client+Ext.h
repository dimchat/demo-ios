//
//  Client+Ext.h
//  DIM
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMClient (Ext)

- (void)login:(DIMUser *)user;

@end

#pragma mark -

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

#pragma mark -

NSString *document_directory(void);

void make_dirs(NSString *dir);

BOOL file_exists(NSString *path);

NS_ASSUME_NONNULL_END
