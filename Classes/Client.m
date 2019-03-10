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

const NSString *kNotificationName_MessageUpdated = @"MessageUpdated";
const NSString *kNotificationName_UsersUpdated = @"UsersUpdated";

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
        
        sp = [[DIMServiceProvider alloc] initWithID:ID];
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
