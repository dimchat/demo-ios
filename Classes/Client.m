//
//  Client.m
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"

#import "Facebook.h"
#import "MessageProcessor.h"

#import "Client.h"

@implementation Client

SingletonImplementations(Client, sharedInstance)

- (void)startWithConfigFile:(NSString *)spConfig {
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:spConfig];
    DIMServiceProvider *sp = nil;
    {
        DIMID *ID = [config objectForKey:@"ID"];
        ID = [DIMID IDWithID:ID];
        DIMID *founder = [config objectForKey:@"founder"];
        founder = [DIMID IDWithID:founder];
        sp = [[DIMServiceProvider alloc] initWithID:ID founderID:founder];
    }
    
    // choose the fast station
    NSArray *stations = [config objectForKey:@"stations"];
    NSDictionary *station = stations.firstObject;
    NSLog(@"got station: %@", station);
    
    // save meta for server ID
    DIMID *ID = [station objectForKey:@"ID"];
    ID = [DIMID IDWithID:ID];
    DIMMeta *meta = [station objectForKey:@"meta"];
    meta = [DIMMeta metaWithMeta:meta];
    [[DIMBarrack sharedInstance] setMeta:meta forID:ID];
    
    // prepare for launch star
    NSMutableDictionary *launchOptions = [[NSMutableDictionary alloc] init];
    NSString *IP = [station objectForKey:@"host"];
    if (IP) {
        //[launchOptions setObject:IP forKey:@"LongLinkAddress"];
        [launchOptions setObject:@"dim.chat" forKey:@"LongLinkAddress"];
        NSDictionary *ipTable = @{
                                  @"dim.chat": @[IP],
                                  };
        [launchOptions setObject:ipTable forKey:@"NewDNS"];
    }
    NSNumber *port = [station objectForKey:@"port"];
    if (port) {
        [launchOptions setObject:port forKey:@"LongLinkPort"];
    }
    
    // connect server
    DIMServer *server = [[DIMServer alloc] initWithDictionary:station];
    _currentStation = server;
    
    Facebook *facebook = [Facebook sharedInstance];
    [facebook addStation:ID provider:sp];
    
    [MessageProcessor sharedInstance];
    
    server.delegate = self;
    [server startWithOptions:launchOptions];
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

#pragma mark - Notification

- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject {
    [self postNotificationName:aName object:anObject userInfo:nil];
}

- (void)postNotificationName:(NSNotificationName)aName
                      object:(nullable id)anObject
                    userInfo:(nullable NSDictionary *)aUserInfo {
    NSNotification *noti = [[NSNotification alloc] initWithName:aName
                                                         object:anObject
                                                       userInfo:aUserInfo];
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc performSelectorOnMainThread:@selector(postNotification:) withObject:noti waitUntilDone:NO];
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
