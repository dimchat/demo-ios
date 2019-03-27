//
//  Client.h
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIApplication.h>
#import <UserNotifications/UserNotifications.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSString *kNotificationName_MessageUpdated;
extern const NSString *kNotificationName_UsersUpdated;

@interface Client : DIMTerminal<UNUserNotificationCenterDelegate>

@property (strong, nonatomic) NSData *deviceToken;

@property (readonly, nonatomic) NSString *displayName;

+ (instancetype)sharedInstance;

@end

@interface Client (AppDelegate)

- (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)didEnterBackground;
- (void)willEnterForeground;
- (void)willTerminate;

@end

@interface Client (APNs)

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

@end

#pragma mark - DOS

NSString *document_directory(void);

void make_dirs(NSString *dir);

BOOL file_exists(NSString *path);
BOOL remove_file(NSString *path);

NS_ASSUME_NONNULL_END
