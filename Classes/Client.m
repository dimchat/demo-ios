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

+ (instancetype)createWithConfigFile:(NSString *)spConfig {
    NSDictionary *gsp = [NSDictionary dictionaryWithContentsOfFile:spConfig];
    NSArray *stations = [gsp objectForKey:@"stations"];
    
    // choose the fast station
    NSDictionary *station = stations.firstObject;
    NSLog(@"got station: %@", station);
    
    // save meta for server ID
    DIMID *ID = [station objectForKey:@"ID"];
    ID = [DIMID IDWithID:ID];
    DIMMeta *meta = [station objectForKey:@"meta"];
    meta = [DIMMeta metaWithMeta:meta];
    [[DIMBarrack sharedInstance] setMeta:meta forID:ID];
    
    // connect server
    DIMStation *server = [[DIMStation alloc] initWithDictionary:station];
    server.delegate = [MessageProcessor sharedInstance];
    
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
    
    Client *client = [self sharedInstance];
    client.currentStation = server;
    [client startWithOptions:launchOptions];
    return client;

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
