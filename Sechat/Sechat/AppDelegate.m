//
//  AppDelegate.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/21.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "MKMImmortals.h"

#import "User.h"
#import "Client.h"
#import "AccountDatabase.h"

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

    [self addDefaultUser:@"baloo@4LA5FNbpxP38UresZVpfWroC2GVomDDZ7q"];
    [self addDefaultUser:@"dim@4TM96qQmGx1UuGtwkdyJAXbZVXufFeT1Xf"];
    
#if DEBUG && 0
    {
        // moky
        NSString *path = [[NSBundle mainBundle] pathForResource:@"usr-moky" ofType:@"plist"];
        DIMLocalUser *user = [DIMLocalUser userWithConfigFile:path];
        [[Client sharedInstance] addUser:user];
    }
#endif
#if DEBUG && 0
    {
        // selina
        NSString *path = [[NSBundle mainBundle] pathForResource:@"usr-selina" ofType:@"plist"];
        DIMLocalUser *user = [DIMLocalUser userWithConfigFile:path];
        [[Client sharedInstance] addUser:user];
    }
#endif
#if DEBUG && 0
    {
        // monkey king
        DIMID *ID = DIMIDWithString(MKM_MONKEY_KING_ID);
        DIMLocalUser *user = DIMUserWithID(ID);
        [[Client sharedInstance] addUser:user];
//        // reset the immortal account's profile
//        MKMImmortals *immortals = [[MKMImmortals alloc] init];
//        DIMProfile * profile = [immortals profileForID:ID];
//        Facebook *facebook = [Facebook sharedInstance];
//        [facebook setProfile:profile forID:ID];
    }
#endif
#if DEBUG && 0
    {
        // hulk
        DIMID *ID = DIMIDWithString(MKM_IMMORTAL_HULK_ID);
        DIMLocalUser *user = DIMUserWithID(ID);
        [[Client sharedInstance] addUser:user];
//        // reset the immortal account's profile
//        MKMImmortals *immortals = [[MKMImmortals alloc] init];
//        DIMProfile * profile = [immortals profileForID:ID];
//        Facebook *facebook = [Facebook sharedInstance];
//        [facebook setProfile:profile forID:ID];
    }
#endif

    return YES;
}

-(void)addDefaultUser:(NSString *)address{
    
    DIMID *ID = DIMIDWithString(address);
    
    NSString *metaPath = [NSString stringWithFormat:@"%@/meta", address];
    NSString *path = [[NSBundle mainBundle] pathForResource:metaPath ofType:@"plist"];
    
    NSDictionary *metaData = [[NSDictionary alloc] initWithContentsOfFile:path];
    DIMMeta *meta = MKMMetaFromDictionary(metaData);
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    [facebook saveMeta:meta forID:ID];
    
    NSString *profilePath = [NSString stringWithFormat:@"%@/profile", address];
    path = [[NSBundle mainBundle] pathForResource:profilePath ofType:@"plist"];
    
    NSDictionary *profileData = [[NSDictionary alloc] initWithContentsOfFile:path];
    DIMProfile *profile = MKMProfileFromDictionary(profileData);
    [facebook saveProfile:profile];
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
