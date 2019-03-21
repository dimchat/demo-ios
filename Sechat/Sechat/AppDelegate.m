//
//  AppDelegate.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/21.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "User.h"
#import "Client.h"

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // GSP station
    NSString *path = [[NSBundle mainBundle] pathForResource:@"gsp" ofType:@"plist"];
    NSMutableDictionary *mDict = [launchOptions mutableCopy];
    if (!mDict) {
        mDict = [[NSMutableDictionary alloc] init];
    }
    [mDict setObject:path forKey:@"ConfigFilePath"];
    
    [[Client sharedInstance] didFinishLaunchingWithOptions:mDict];
    
#if DEBUG && 0
    {
        // moky
        NSString *path = [[NSBundle mainBundle] pathForResource:@"usr-moky" ofType:@"plist"];
        DIMUser *user = [DIMUser userWithConfigFile:path];
        [[Client sharedInstance] addUser:user];
    }
#endif
#if DEBUG && 0
    {
        // selina
        NSString *path = [[NSBundle mainBundle] pathForResource:@"usr-selina" ofType:@"plist"];
        DIMUser *user = [DIMUser userWithConfigFile:path];
        [[Client sharedInstance] addUser:user];
    }
#endif
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[Client sharedInstance] didEnterBackground];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
    [[Client sharedInstance] willEnterForeground];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[Client sharedInstance] willTerminate];
}

#pragma mark - APNs

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // APNs register success
    [[Client sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // APNs register failed
    [[Client sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // APNs receive notification
    [[Client sharedInstance] didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

@end
