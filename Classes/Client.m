//
//  Client.m
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSObject+JsON.h"

#import "Facebook.h"
#import "MessageProcessor.h"

#import "Client.h"

const NSString *kNotificationName_MessageUpdated = @"MessageUpdated";
const NSString *kNotificationName_UsersUpdated = @"UsersUpdated";

@implementation Client

SingletonImplementations(Client, sharedInstance)

@end

@implementation Client (AppDelegate)

- (void)_startServer:(NSDictionary *)station withProvider:(DIMServiceProvider *)sp {
    // save meta for server ID
    DIMID *ID = [station objectForKey:@"ID"];
    ID = [DIMID IDWithID:ID];
    DIMMeta *meta = [station objectForKey:@"meta"];
    meta = [DIMMeta metaWithMeta:meta];
    [[DIMBarrack sharedInstance] setMeta:meta forID:ID];
    
    // prepare for launch star
    NSMutableDictionary *serverOptions = [[NSMutableDictionary alloc] init];
    NSString *IP = [station objectForKey:@"host"];
    if (IP) {
        //[launchOptions setObject:IP forKey:@"LongLinkAddress"];
        [serverOptions setObject:@"dim.chat" forKey:@"LongLinkAddress"];
        NSDictionary *ipTable = @{
                                  @"dim.chat": @[IP],
                                  };
        [serverOptions setObject:ipTable forKey:@"NewDNS"];
    }
    NSNumber *port = [station objectForKey:@"port"];
    if (port) {
        [serverOptions setObject:port forKey:@"LongLinkPort"];
    }
    
    // connect server
    DIMServer *server = [[DIMServer alloc] initWithDictionary:station];
    _currentStation = server;
    
    Facebook *facebook = [Facebook sharedInstance];
    [facebook addStation:ID provider:sp];
    
    [MessageProcessor sharedInstance];
    
    server.delegate = self;
    [server startWithOptions:serverOptions];
}

- (void)_launchServiceProviderConfig:(NSDictionary *)config {
    DIMServiceProvider *sp = nil;
    {
        DIMID *ID = [config objectForKey:@"ID"];
        ID = [DIMID IDWithID:ID];
        DIMID *founder = [config objectForKey:@"founder"];
        founder = [DIMID IDWithID:founder];
        
        sp = [[DIMServiceProvider alloc] initWithID:ID];
    }
    
    // choose the fast station
    NSArray *stations = [config objectForKey:@"stations"];
    NSDictionary *station = stations.firstObject;
    NSLog(@"got station: %@", station);
    [self _startServer:station withProvider:sp];
}

- (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIApplication *app = [UIApplication sharedApplication];
    
    // APNs
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        // TODO:
        // ...
        
        // clear icon badge
        NSInteger badge = app.applicationIconBadgeNumber;
        if (badge > 0) {
            badge = 0;
            app.applicationIconBadgeNumber = badge;
        }
    }
    [app registerForRemoteNotifications];
    //UNUserNotificationCenter *nc = [UNUserNotificationCenter defaultCenter];
    //[nc requestAuthorizationWithOptions:completionHandler:];
    
    // launch server
    NSString *spConfig = [launchOptions objectForKey:@"ConfigFilePath"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:spConfig];
    [self _launchServiceProviderConfig:config];
}

- (void)didEnterBackground {
    [_currentStation pause];
}

- (void)willEnterForeground {
    [_currentStation resume];
}

- (void)willTerminate {
    [_currentStation end];
}

@end

@implementation Client (APNs)

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [deviceToken UTF8String];
    NSLog(@"APNs token: %@", token);
    // TODO: send this device token to server
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"APNs failed to get token: %@", error);
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"APNs user info: %@", userInfo);
}

@end

#pragma mark - DOS

NSString *document_directory(void) {
    NSArray *paths;
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask, YES);
    return paths.firstObject;
}

void make_dirs(NSString *dir) {
    // check base directory exists
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir isDirectory:nil]) {
        NSError *error = nil;
        // make sure directory exists
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                       attributes:nil error:&error];
        assert(!error);
    }
}

BOOL file_exists(NSString *path) {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:path];
}

BOOL remove_file(NSString *path) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSError *err = nil;
        [fm removeItemAtPath:path error:&err];
        if (err) {
            NSLog(@"failed to remove file: %@", err);
            return NO;
        }
    }
    return YES;
}
