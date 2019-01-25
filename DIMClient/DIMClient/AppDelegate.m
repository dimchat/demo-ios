//
//  AppDelegate.m
//  DIMClient
//
//  Created by Albert Moky on 2018/12/21.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "NSObject+JsON.h"

#import "Facebook.h"
#import "Station.h"

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [Facebook sharedInstance];
    
    DIMClient *client = [DIMClient sharedInstance];
    DIMBarrack *barrack = [DIMBarrack sharedInstance];
    DIMTransceiver *trans = [DIMTransceiver sharedInstance];
    
    DIMID *ID;
    DIMUser *user;
    
    // Monkey King
    ID = [DIMID IDWithID:MKM_MONKEY_KING_ID];
    user = MKMUserWithID(ID);
    [client addUser:user];
    
    // Immortal Hulk
    ID = [DIMID IDWithID:MKM_IMMORTAL_HULK_ID];
    user = MKMUserWithID(ID);
    [client addUser:user];
    
    // GSP station
    NSString *path = [[NSBundle mainBundle] pathForResource:@"gsp-moky" ofType:@"plist"];
    NSDictionary *gsp = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *stations = [gsp objectForKey:@"stations"];
    NSDictionary *station = stations.firstObject;
    
    // save meta for server ID
    ID = [station objectForKey:@"ID"];
    ID = [DIMID IDWithID:ID];
    DIMMeta *meta = [station objectForKey:@"meta"];
    meta = [DIMMeta metaWithMeta:meta];
    [barrack setMeta:meta forID:ID];
    
    // connect server
    Station *server = [[Station alloc] initWithDictionary:station];
    client.currentStation = server;
    trans.delegate = server;
    
    [self performSelector:@selector(delayAction) withObject:nil afterDelay:3.0];
    
    return YES;
}

- (void)delayAction {
    DIMClient *client = [DIMClient sharedInstance];
    [(Station *)client.currentStation handshake];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
