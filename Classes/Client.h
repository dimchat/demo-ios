//
//  Client.h
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSString *kNotificationName_MessageUpdated;
extern const NSString *kNotificationName_UsersUpdated;

@interface Client : DIMTerminal

+ (instancetype)sharedInstance;

- (void)startWithConfigFile:(NSString *)spConfig;
- (void)didEnterBackground;
- (void)willEnterForeground;
- (void)willTerminate;

@end

#pragma mark - DOS

NSString *document_directory(void);

void make_dirs(NSString *dir);

BOOL file_exists(NSString *path);
BOOL remove_file(NSString *path);

NS_ASSUME_NONNULL_END
