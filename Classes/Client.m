//
//  Client.m
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSData+Extension.h"

#import "MKMImmortals.h"

#import "Facebook+Profile.h"
#import "Facebook+Register.h"
#import "MessageDatabase.h"

#import "Client.h"

@interface Client () {
    
    NSString *_userAgent;
}

@end

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

- (void)onHandshakeAccepted:(NSString *)session {
    [super onHandshakeAccepted:session];
    
    // post device token
    NSString *token = MKMHexEncode(self.deviceToken);
    if (token) {
        DIMCommand *cmd = [[DIMCommand alloc] initWithCommand:@"broadcast"];
        [cmd setObject:@"apns" forKey:@"title"];
        [cmd setObject:token forKey:@"device_token"];
        
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger sendCommand:cmd];
    }
}

@end

@implementation Client (AppDelegate)

- (void)_startServer:(NSDictionary *)station withProvider:(DIMServiceProvider *)sp {
    // save meta for server ID
    DIMID *ID = DIMIDWithString([station objectForKey:@"ID"]);
    DIMMeta *meta = MKMMetaFromDictionary([station objectForKey:@"meta"]);
    
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    [facebook saveMeta:meta forID:ID];
    
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
    DIMServer *server = [[DIMServer alloc] initWithDictionary:station];
    server.delegate = self;
    [server startWithOptions:serverOptions];
    _currentStation = server;
    
    [MessageDatabase sharedInstance];
    
    DIMMessenger *messenger = [DIMMessenger sharedInstance];
    [messenger setContextValue:server forName:@"server"];
    
    // scan users
    NSArray<DIMUser *> *users = [facebook localUsers];
#if DEBUG && 0
    NSMutableArray *mArray;
    if (users.count > 0) {
        mArray = [users mutableCopy];
    } else {
        mArray = [[NSMutableArray alloc] initWithCapacity:2];
    }
    [mArray addObject:DIMIDWithString(MKM_IMMORTAL_HULK_ID)];
    [mArray addObject:DIMIDWithString(MKM_MONKEY_KING_ID)];
    users = mArray;
#endif
    // add users
    for (DIMUser *user in users) {
        NSLog(@"[client] add user: %@", user);
        [self addUser:user];
        facebook.currentUser = user;
    }
}

- (void)_launchServiceProviderConfig:(NSDictionary *)config {
    
    DIMID *ID = DIMIDWithString([config objectForKey:@"ID"]);
    DIMServiceProvider *sp = [[DIMServiceProvider alloc] initWithID:ID];
    
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
    
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    DIMUser *user = facebook.currentUser;
    
    if(user != nil){
        // report client state
        DIMCommand *cmd = [[DIMCommand alloc] initWithCommand:@"broadcast"];
        [cmd setObject:@"report" forKey:@"title"];
        [cmd setObject:@"background" forKey:@"state"];
        
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger sendCommand:cmd];
    }
    [_currentStation pause];
}

- (void)willEnterForeground {
    [_currentStation resume];
    
    // clear icon badge
    UIApplication *app = [UIApplication sharedApplication];
    app.applicationIconBadgeNumber = 0;
    UNUserNotificationCenter *nc = [UNUserNotificationCenter currentNotificationCenter];
    [nc removeAllPendingNotificationRequests];
    
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    DIMUser *user = facebook.currentUser;
    
    if(user != nil){
        // report client state
        DIMCommand *cmd = [[DIMCommand alloc] initWithCommand:@"broadcast"];
        [cmd setObject:@"report" forKey:@"title"];
        [cmd setObject:@"foreground" forKey:@"state"];
        
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger sendCommand:cmd];
    }
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

- (BOOL)saveUser:(DIMID *)ID meta:(DIMMeta *)meta privateKey:(DIMPrivateKey *)SK name:(nullable NSString *)nickname {
    
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    
    // 1. save meta & private key
    if (![facebook savePrivateKey:SK user:ID]) {
        NSAssert(false, @"failed to save private key for new user: %@", ID);
        return NO;
    }
    if (![facebook saveMeta:meta forID:ID]) {
        NSAssert(false, @"failed to save meta for new user: %@", ID);
        return NO;
    }

    // 2. save nickname in profile
    if (nickname.length > 0) {
        
        DIMProfile *profile = [[DIMProfile alloc] initWithID:ID];

        [profile setName:nickname];
        [profile sign:SK];
        if (![facebook saveProfile:profile]) {
            NSAssert(false, @"failedo to save profile for new user: %@", ID);
            return NO;
        }
    }
    
    // 3. create user for client
    DIMUser *user = [[DIMUser alloc] initWithID:ID];
    user.dataSource = facebook;
    self.currentUser = user;
    
    BOOL saved = [facebook saveUserList:self.users withCurrentUser:user];
    NSAssert(saved, @"failed to save users: %@, current user: %@", self.users, user);
    return saved;
}

- (BOOL)importUser:(DIMID *)ID meta:(DIMMeta *)meta privateKey:(DIMPrivateKey *)SK {
    
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    
    // 1. save meta & private key
    if (![facebook savePrivateKey:SK user:ID]) {
        NSAssert(false, @"failed to save private key for new user: %@", ID);
        return NO;
    }
    if (![facebook saveMeta:meta forID:ID]) {
        NSAssert(false, @"failed to save meta for new user: %@", ID);
        return NO;
    }
    
    MKMUser *user = DIMUserWithID(ID);
    [self login:user];
    
    BOOL saved = [facebook saveUserList:self.users withCurrentUser:user];
    NSAssert(saved, @"failed to save users: %@, current user: %@", self.users, user);
    
    return saved;
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
