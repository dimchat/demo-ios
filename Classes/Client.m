//
//  Client.m
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSObject+JsON.h"
#import "NSData+Crypto.h"

#import "Facebook.h"
#import "MessageProcessor.h"

#import "Client.h"

const NSString *kNotificationName_MessageUpdated = @"MessageUpdated";
const NSString *kNotificationName_UsersUpdated = @"UsersUpdated";

@implementation Client

SingletonImplementations(Client, sharedInstance)

- (NSString *)displayName {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *name = [info valueForKey:@"CFBundleDisplayName"];
    if (name) {
        return name;
    }
    return @"DIM!";
}

- (void)onHandshakeAccepted:(const NSString *)session {
    [super onHandshakeAccepted:session];
    
    // post device token
    NSString *token = [self.deviceToken hexEncode];
    if (token) {
        DIMBroadcastCommand *cmd;
        cmd = [[DIMBroadcastCommand alloc] initWithTitle:@"apns"];
        [cmd setObject:token forKey:@"device_token"];
        [self sendCommand:cmd];
    }
}

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
    if (port != nil) {
        [serverOptions setObject:port forKey:@"LongLinkPort"];
    }
    
    // configure FTP server
    DIMFileServer *ftp = [DIMFileServer sharedInstance];
    ftp.userAgent = self.userAgent;
    ftp.uploadAPI = @"http://124.156.108.150:8081/{ID}/upload";
    ftp.downloadAPI = @"http://124.156.108.150:8081/download/{ID}/{filename}";
    ftp.avatarAPI = @"http://124.156.108.150:8081/{ID}/avatar.{ext}";
    
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
//        DIMID *founder = [config objectForKey:@"founder"];
//        founder = [DIMID IDWithID:founder];
        
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
    
    UNUserNotificationCenter *nc = [UNUserNotificationCenter currentNotificationCenter];
    nc.delegate = self;
    
    UNAuthorizationOptions options = UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert;
    [nc requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        NSLog(@"APNs requestAuthorizationWithOptions completed");
    }];
    
    // launch server
    NSString *spConfig = [launchOptions objectForKey:@"ConfigFilePath"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:spConfig];
    [self _launchServiceProviderConfig:config];
    
    // clear icon badge
    app.applicationIconBadgeNumber = 0;
    [nc removeAllPendingNotificationRequests];
}

- (void)didEnterBackground {
    // report client state
    DIMBroadcastCommand *cmd;
    cmd = [[DIMBroadcastCommand alloc] initWithTitle:@"report"];
    [cmd setObject:@"background" forKey:@"state"];
    [self sendCommand:cmd];
    
    [_currentStation pause];
}

- (void)willEnterForeground {
    [_currentStation resume];
    
    // clear icon badge
    UIApplication *app = [UIApplication sharedApplication];
    app.applicationIconBadgeNumber = 0;
    UNUserNotificationCenter *nc = [UNUserNotificationCenter currentNotificationCenter];
    [nc removeAllPendingNotificationRequests];
    
    // report client state
    DIMBroadcastCommand *cmd;
    cmd = [[DIMBroadcastCommand alloc] initWithTitle:@"report"];
    [cmd setObject:@"foreground" forKey:@"state"];
    [self sendCommand:cmd];
}

- (void)willTerminate {
    [_currentStation end];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSLog(@"willPresentNotification: %@", notification);
    // show alert even in foreground
    completionHandler(UNNotificationPresentationOptionAlert);
}

@end

@implementation Client (APNs)

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [deviceToken hexEncode];
    NSLog(@"APNs token: %@", deviceToken);
    NSLog(@"APNs token(hex): %@", token);
    // TODO: send this device token to server
    if (deviceToken.length > 0) {
        self.deviceToken = deviceToken;
    }
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"APNs failed to get token: %@", error);
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"APNs user info: %@", userInfo);
    UIApplication *app = [UIApplication sharedApplication];
    UIApplicationState applicationState = app.applicationState;
    switch (applicationState) {
        case UIApplicationStateActive: {
            
        }
            break;
            
        case UIApplicationStateInactive: {
            
        }
            break;
            
        case UIApplicationStateBackground: {
            
        }
            break;
            
        default:
            break;
    }
}

@end

#pragma mark - DOS

NSString *document_directory(void) {
    NSArray *paths;
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask, YES);
    return paths.firstObject;
}

NSString *caches_directory(void) {
    NSArray *paths;
    paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
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
