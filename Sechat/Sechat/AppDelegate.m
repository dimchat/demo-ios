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
#import "AppDelegate.h"
#import "ConversationsTableViewController.h"
#import "ContactsTableViewController.h"
#import "AccountTableViewController.h"
#import "WelcomeViewController.h"
#import "UIColor+Extension.h"
#import "LocalDatabaseManager.h"
#import "FolderUtility.h"
#import "DIMClientConstants.h"
#import "NSObject+JsON.h"

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
    [self addDefaultUser:@"assistant@2PpB6iscuBjA15oTjAsiswoX9qis5V3c1Dq"];
    
    [[LocalDatabaseManager sharedInstance] createTables];
    [self convertOldTables];
    
    [self setAppApearence];
    self.tabbarController = [self createTabBarController];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.tabbarController;
    [self.window makeKeyAndVisible];
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    if (!user) {
        
        WelcomeViewController *vc = [[WelcomeViewController alloc] init];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
        nc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.tabbarController presentViewController:nc animated:NO completion:nil];
    }
    
    [self updateBadge:nil];
    [self addObservers];
    
    [client getMuteList];
    [self getReviewStatus];

    return YES;
}

-(void)getReviewStatus{
    
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(backgroundQueue, ^{
        
        NSError *error;
        NSString *url = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=1481849344"];
        NSString *responseString = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&error];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"in_review"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSDictionary *dic = [[responseString data] jsonDictionary];
        
        if(dic != nil && [dic isKindOfClass:[NSDictionary class]]){
            
            //DBG(@"The return dic is : %@", dic);
            @try{
                NSString *appStoreVersion = dic[@"results"][0][@"version"];
                NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

                if([currentVersion compare:appStoreVersion] != NSOrderedDescending){
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"in_review"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }

            }@catch(NSException *e){

            }
        }
    });
}

-(void)addObservers{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBadge:) name:DIMConversationUpdatedNotification object:nil];
}

-(void)updateBadge:(NSNotification *)o{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSInteger unreadCount = [[LocalDatabaseManager sharedInstance] getUnreadMessageCount:nil];
        
        NSString *badgeValue = nil;
        if(unreadCount > 0 && unreadCount <= 99){
            badgeValue = [NSString stringWithFormat:@"%zd", unreadCount];
        }else if(unreadCount > 99){
            badgeValue = @"99+";
        }
        
        UITabBarItem *tabBarItem = self.tabbarController.tabBar.items[0];
        tabBarItem.badgeValue = badgeValue;
        
        [UIApplication sharedApplication].applicationIconBadgeNumber = unreadCount;
        
    });
}

-(void)setAppApearence{
    
    UIColor *tintColor = [UIColor colorWithHexString:@"0a81ff"];
    
    [[UIButton appearance] setTitleColor:tintColor forState:UIControlStateNormal];
    [[UIActivityIndicatorView appearance] setColor:tintColor];
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
    conversationNavigationController.navigationBar.prefersLargeTitles = YES;
    UINavigationController *contactNavigationController = [[UINavigationController alloc] initWithRootViewController:self.contactController];
    contactNavigationController.navigationBar.prefersLargeTitles = YES;
    UINavigationController *accountNavigationController = [[UINavigationController alloc] initWithRootViewController:self.accountController];
    accountNavigationController.navigationBar.prefersLargeTitles = YES;
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.delegate = self;
    tabBarController.viewControllers = @[conversationNavigationController, contactNavigationController, accountNavigationController];
    
    UITabBarItem *tabBarItem = tabBarController.tabBar.items[0];
    tabBarItem.title = NSLocalizedString(@"Chats", @"title");
    tabBarItem.image = [UIImage imageNamed:@"tabbar_chat"];
    
    tabBarItem = tabBarController.tabBar.items[1];
    tabBarItem.title = NSLocalizedString(@"Contacts", @"title");
    tabBarItem.image = [UIImage imageNamed:@"tabbar_contact"];
    
    tabBarItem = tabBarController.tabBar.items[2];
    tabBarItem.title = NSLocalizedString(@"Settings", @"title");
    tabBarItem.image = [UIImage imageNamed:@"tabbar_setting"];
    
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
    [self updateBadge:nil];
    [self addObservers];
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

#pragma mark - Convert old tables

-(void)convertOldTables{
    
    LocalDatabaseManager *sqliteManager = [LocalDatabaseManager sharedInstance];
    
    NSString *dir = [[FolderUtility sharedInstance] applicationDocumentsDirectory];
    dir = [dir stringByAppendingPathComponent:@".dim"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *de = [fm enumeratorAtPath:dir];
        
    DIMID *ID;
    DIMAddress *address;
    NSString *string;

    NSString *path;
    
    while (path = [de nextObject]) {
        if (![path hasSuffix:@"/messages.plist"]) {
            continue;
        }
        
        string = [path substringToIndex:(path.length - 15)];
        address = MKMAddressFromString(string);
            
        ID = DIMIDWithAddress(address);
        NSString *plistPath = [NSString stringWithFormat:@"%@/%@", dir, path];
        
        if ([ID isValid]) {
            
            [sqliteManager insertConversation:ID];
            
            //Get All Conversation Messages
            NSArray *array = [NSArray arrayWithContentsOfFile:plistPath];
            if (!array) {
                NSLog(@"messages not found: %@", plistPath);
                continue;
            }
            
            NSLog(@"messages from %@", plistPath);
            for (NSDictionary *item in array) {
                DIMInstantMessage *msg = DKDInstantMessageFromDictionary(item);
                if (!msg) {
                    NSAssert(false, @"message invalid: %@", item);
                    continue;
                }
                
                [sqliteManager addMessage:msg toConversation:ID];
            }
            
            NSError *error;
            [fm removeItemAtPath:plistPath error:&error];
            
        } else {
            NSLog(@"failed to load message in path: %@", plistPath);
        }
    }
    
    NSLog(@"Convert Finish");
}

@end
