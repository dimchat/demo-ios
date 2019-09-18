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
#import "Facebook.h"
#import "AppDelegate.h"
#import "ConversationsTableViewController.h"
#import "ContactsTableViewController.h"
#import "AccountTableViewController.h"
#import "WelcomeViewController.h"
#import "UIColor+Extension.h"

@interface AppDelegate ()<UITabBarControllerDelegate>

@property(nonatomic, strong) UITabBarController *tabbarController;
@property(nonatomic, strong) ConversationsTableViewController *conversationController;
@property(nonatomic, strong) ContactsTableViewController *contactController;
@property(nonatomic, strong) AccountTableViewController *accountController;

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
    
    [self setAppApearence];
    self.tabbarController = [self createTabBarController];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = self.tabbarController;
    [self.window makeKeyAndVisible];
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = client.currentUser;
    if (!user) {
        
        WelcomeViewController *vc = [[WelcomeViewController alloc] init];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.tabbarController presentViewController:nc animated:NO completion:nil];
    }

    return YES;
}

-(void)setAppApearence{
    
    UIColor *tintColor = [UIColor colorWithHexString:@"0a81ff"];
    
    [[UIButton appearance] setTitleColor:tintColor forState:UIControlStateNormal];
    [[UIActivityIndicatorView appearance] setColor:tintColor];
    
    //[[UITabBar appearance] setTintColor:tintColor];
    //[[UIToolbar appearance] setTintColor:tintColor];
    //[[UITextField appearance] setTintColor:tintColor];
    //[UISwitch appearance].onTintColor = tintColor;
    //[[UITableView appearance] setBackgroundColor:APP_MAIN_BACKGROUND_COLOR];
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

- (UITabBarController *)createTabBarController {
    
    self.conversationController = [[ConversationsTableViewController alloc] init];
    self.contactController = [[ContactsTableViewController alloc] init];
    self.accountController = [[AccountTableViewController alloc] init];
    
    UINavigationController *conversationNavigationController = [[UINavigationController alloc] initWithRootViewController:self.conversationController];
    UINavigationController *contactNavigationController = [[UINavigationController alloc] initWithRootViewController:self.contactController];
    UINavigationController *accountNavigationController = [[UINavigationController alloc] initWithRootViewController:self.accountController];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.delegate = self;
    tabBarController.viewControllers = @[conversationNavigationController, contactNavigationController, accountNavigationController];
    
    UITabBarItem *tabBarItem = tabBarController.tabBar.items[0];
    tabBarItem.title = NSLocalizedString(@"Chats", @"title");
    
    tabBarItem = tabBarController.tabBar.items[1];
    tabBarItem.title = NSLocalizedString(@"Contacts", @"title");
    
    tabBarItem = tabBarController.tabBar.items[2];
    tabBarItem.title = NSLocalizedString(@"Settings", @"title");
    
    return tabBarController;
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
