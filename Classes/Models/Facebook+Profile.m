//
//  Facebook+Profile.m
//  Sechat
//
//  Created by Albert Moky on 2019/6/27.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSObject+Extension.h"
#import "NSDictionary+Binary.h"

#import "Client.h"

#import "Facebook+Profile.h"

static inline NSString *base_directory(DIMID ID) {
    // base directory ("Documents/.mkm/{address}")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    return [dir stringByAppendingPathComponent:(NSString *)ID.address];
}

/**
 Get avatar filepath in Documents Directory
 
 @param ID - user ID
 @param filename - "xxxx.png"
 @return "Documents/.mkm/{address}/avatars/xxxx.png"
 */
static inline NSString *avatar_filepath(DIMID ID, NSString * _Nullable filename, BOOL autoCreate) {
    NSString *dir = base_directory(ID);
    dir = [dir stringByAppendingPathComponent:@"avatars"];
    // check base directory exists
    if (autoCreate && !file_exists(dir)) {
        // make sure directory exists
        make_dirs(dir);
    }
    if (filename.length == 0) {
        filename = @"avatar.png";
    }
    return [dir stringByAppendingPathComponent:filename];
}

NSString * const kNotificationName_AvatarUpdated = @"AvatarUpdated";

@implementation DIMFacebook (Avatar)

- (BOOL)saveAvatar:(NSData *)data
              name:(nullable NSString *)filename
             forID:(DIMID)ID {
    
    UIImage *image = [UIImage imageWithData:(NSData *)data];
    if (image.size.width < 32) {
        NSAssert(false, @"avatar image error: %@", data);
        return NO;
    }
    NSLog(@"avatar OK: %@", image);
    NSString *path = avatar_filepath(ID, filename, YES);
    [data writeToFile:path atomically:YES];
    
    // TODO: post notice 'AvatarUpdated'
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNotificationName_AvatarUpdated
                      object:self userInfo:@{@"ID": ID}];
    return YES;
}

- (void)_downloadAvatar:(NSURL *)url savePath:(NSString *)path forID:(DIMID)ID {
    
    static NSMutableArray *s_downloadings = nil;
    SingletonDispatchOnce(^{
        s_downloadings = [[NSMutableArray alloc] init];
    });
    
    // check & add task
    if ([s_downloadings containsObject:url]) {
        NSLog(@"the job already exists: %@", url);
        return ;
    }
    [s_downloadings addObject:url];

    NSLog(@"avatar downloading from %@", url);
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSLog(@"avatar downloaded (%lu bytes) from %@, save to %@", data.length, url, path);
    if (data.length > 0) {
        [self saveAvatar:data name:[path lastPathComponent] forID:ID];
    }
    
    // remove task
    [s_downloadings removeObject:url];
}

// Cache directory: "Documents/.mkm/{address}/avatar.png"
- (nullable UIImage *)loadAvatarWithURL:(NSString *)urlString forID:(DIMID)ID {
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *filename = [url lastPathComponent];
    NSString *path = avatar_filepath(ID, filename, NO);
    
    if (file_exists(path)) {
        return [UIImage imageWithContentsOfFile:path];
    }
    // download in background
    [NSObject performBlockInBackground:^{
        [self _downloadAvatar:url savePath:path forID:ID];
    }];
    return nil;
}

@end
