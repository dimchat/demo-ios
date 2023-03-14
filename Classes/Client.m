//
//  Client.m
//  DIMP
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMConstants.h"
#import "DIMGlobalVariable.h"
#import "DIMSharedFacebook.h"

#import "Facebook+Profile.h"
#import "Facebook+Register.h"
#import "MessageDatabase.h"
//#import "JPUSHService.h"
#import "Client.h"

@interface Client () {
    
    NSString *_userAgent;
}

@end

@implementation Client

OKSingletonImplementations(Client, sharedInstance)

- (NSString *)displayName {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *name = [info valueForKey:@"CFBundleDisplayName"];
    if (name) {
        return name;
    }
    return @"DIM!";
}

- (NSString *)userAgent {
    if (!_userAgent) {
        // device model & system
        UIDevice *device = [UIDevice currentDevice];
        NSString *model = device.model;          // e.g. @"iPhone", @"iPod touch"
        NSString *sysName = device.systemName;   // e.g. @"iOS"
        NSString *sysVer = device.systemVersion; // e.g. @"4.0"
        
        // current language
        NSString *lang = self.language;
        
        NSString *format = @"DIMP/1.0 (%@; U; %@ %@; %@) DIMCoreKit/1.0 (Terminal, like WeChat) DIM-by-GSP/1.0.1";
        _userAgent = [[NSString alloc] initWithFormat:format, model, sysName, sysVer, lang];
        NSLog(@"User-Agent: %@", _userAgent);
    }
    return _userAgent;
}

//#pragma mark DIMStationDelegate
//
//- (void)station:(DIMStation *)server onHandshakeAccepted:(NSString *)session {
//    [super station:server onHandshakeAccepted:session];
//    
//    // post device token
//    NSString *token = MKMHexEncode(self.deviceToken);
//    if (token) {
//        DIMCommand *content = [[DIMCommand alloc] initWithCommandName:@"broadcast"];
//        [content setObject:@"apns" forKey:@"title"];
//        [content setObject:token forKey:@"device_token"];
//        
//        DIMMessenger *messenger = [DIMMessenger sharedInstance];
//        [messenger sendCommand:content];
//    }
//}

#pragma mark FSM

// Override
- (void)machine:(DIMSessionStateMachine *)ctx exitState:(id<FSMState>)previous
           time:(NSTimeInterval)now {
    DIMSessionState *current = [ctx currentState];
    NSLog(@"session state changed: %@ => %@", previous, current);
    NSUInteger index = [current index];
    NSDictionary *info = @{
        @"stateIndex": @(index),
    };
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNotificationName_ServerStateChanged
                      object:self
                    userInfo:info];

    [super machine:ctx exitState:previous time:now];
}

@end

@implementation Client (AppDelegate)

- (void)_startServer:(NSDictionary *)station withProvider:(DIMServiceProvider *)sp {
    DIMSharedFacebook *facebook = [DIMGlobal facebook];
    
    // save meta for server ID
    id<MKMID> ID = MKMIDParse([station objectForKey:@"ID"]);
    id<MKMMeta> meta = MKMMetaParse([station objectForKey:@"meta"]);
    
    if (meta) {
        [facebook saveMeta:meta forID:ID];
    }
    
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
    ftp.uploadAPI = self.uploadAPI;
    ftp.downloadAPI = self.downloadAPI;
    ftp.avatarAPI = self.avatarAPI;
    
    // connect server
    [self connectToHost:IP port:[port unsignedShortValue]];
    
    // get user from database and login
    id<MKMUser> user = [facebook currentUser];
    if (user) {
        [self loginWithID:user.ID];
    }
}

- (void)_launchServiceProviderConfig:(NSDictionary *)config {
    
    id<MKMID> ID = MKMIDParse([config objectForKey:@"ID"]);
    DIMServiceProvider *sp = [[DIMServiceProvider alloc] initWithID:ID];
    
    // choose the fast station
    NSArray *stations = [config objectForKey:@"stations"];
    NSDictionary *station = stations.firstObject;
    NSLog(@"got station: %@", station);
    
    [self _startServer:station withProvider:sp];
}

- (void)didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    UIApplication *app = [UIApplication sharedApplication];
//
//    // APNs
//    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
//        // TODO:
//        // ...
//
//        // clear icon badge
//        NSInteger badge = app.applicationIconBadgeNumber;
//        if (badge > 0) {
//            badge = 0;
//            app.applicationIconBadgeNumber = badge;
//        }
//    }
//    [app registerForRemoteNotifications];
//
//    UNUserNotificationCenter *nc = [UNUserNotificationCenter currentNotificationCenter];
//    nc.delegate = self;
//
//    UNAuthorizationOptions options = UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionAlert;
//    [nc requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
//        NSLog(@"APNs requestAuthorizationWithOptions completed");
//    }];
    
    // launch server
    NSString *spConfig = [launchOptions objectForKey:@"ConfigFilePath"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:spConfig];
    [self _launchServiceProviderConfig:config];
    
    // clear icon badge
//    app.applicationIconBadgeNumber = 0;
//    [nc removeAllPendingNotificationRequests];
}

//- (void)didEnterBackground {
//    [self reportOffline];
//    [_currentStation pause];
//}
//
//- (void)willEnterForeground {
//    [_currentStation resume];
//    [self reportOnline];
//
//    // clear icon badge
//    UIApplication *app = [UIApplication sharedApplication];
//    app.applicationIconBadgeNumber = 0;
//    UNUserNotificationCenter *nc = [UNUserNotificationCenter currentNotificationCenter];
//    [nc removeAllPendingNotificationRequests];
//}
//
//- (void)willTerminate {
//    [_currentStation end];
//}

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
    NSString *token = MKMHexEncode(deviceToken);
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

-(void)setPushAlias{
    
    if(self.currentUser != nil){
//        NSString *alias = self.currentUser.ID.address;
//        [JPUSHService setAlias:alias completion:^(NSInteger iResCode, NSString *iAlias, NSInteger seq) {
//            NSLog(@"Response code %zd", iResCode);
//            NSLog(@"Response code %@", iAlias);
//            NSLog(@"Response code %zd", seq);
//        } seq:0];
    }
}

@end

@implementation Client (API)

- (NSString *)uploadAPI {
    return @"https://sechat.dim.chat/{ID}/upload";
}

- (NSString *)downloadAPI {
    return @"https://sechat.dim.chat/download/{ID}/{filename}";
}

- (NSString *)avatarAPI {
    return @"https://sechat.dim.chat/avatar/{ID}/{filename}";
}

- (NSString *)reportAPI {
    return @"https://sechat.dim.chat/report?type={type}&identifier={ID}&sender={sender}";
}

- (NSString *)termsAPI {
    return @"https://wallet.dim.chat/dimchat/sechat/privacy.html";
}

- (NSString *)aboutAPI {
    //return @"https://dim.chat/sechat";
    return @"https://sechat.dim.chat/support";
}

@end

@implementation Client (Register)

- (BOOL)importUser:(id<MKMID>)ID meta:(id<MKMMeta>)meta privateKey:(id<MKMPrivateKey>)SK {
    
    DIMSharedFacebook *facebook = [DIMGlobal facebook];
    
    // 1. save meta & private key
    if (![facebook savePrivateKey:SK withType:DIMPrivateKeyType_Meta forUser:ID]) {
        NSAssert(false, @"failed to save private key for new user: %@", ID);
        return NO;
    }
    if (![facebook saveMeta:meta forID:ID]) {
        NSAssert(false, @"failed to save meta for new user: %@", ID);
        return NO;
    }
    
    id<MKMUser> user = DIMUserWithID(ID);
    [self loginWithID:ID];
    
    BOOL saved = [facebook saveUserList:self.users withCurrentUser:user];
    NSAssert(saved, @"failed to save users: %@, current user: %@", self.users, user);
    
    return saved;
}

- (id<MKMUser>)currentUser {
    DIMSharedFacebook *facebook = [DIMGlobal facebook];
    return [facebook currentUser];
}

- (NSArray<id<MKMUser>> *)users {
    DIMSharedFacebook *facebook = [DIMGlobal facebook];
    return [facebook localUsers];
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
