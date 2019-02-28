//
//  Client.h
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface Client : DIMTerminal

+ (instancetype)sharedInstance;

- (void)startWithConfigFile:(NSString *)spConfig;

#pragma mark - Notification

- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

@end

#pragma mark - DOS

NSString *document_directory(void);

void make_dirs(NSString *dir);

BOOL file_exists(NSString *path);

NS_ASSUME_NONNULL_END
