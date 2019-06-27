//
//  Facebook+Profile.m
//  Sechat
//
//  Created by Albert Moky on 2019/6/27.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSDictionary+Binary.h"

#import "NSNotificationCenter+Extension.h"

#import "Client.h"

#import "Facebook+Profile.h"

static inline NSString *base_directory(DIMID *ID) {
    // base directory ("Documents/.mkm/{address}")
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".mkm"];
    return [dir stringByAppendingPathComponent:(NSString *)ID.address];
}

/**
 Get profile filepath in Documents Directory
 
 @param ID - entity ID
 @return "Documents/.mkm/{address}/profile.plist"
 */
static inline NSString *profile_filepath(DIMID *ID, BOOL autoCreate) {
    NSString *dir = base_directory(ID);
    // check base directory exists
    if (autoCreate && !file_exists(dir)) {
        // make sure directory exists
        make_dirs(dir);
    }
    return [dir stringByAppendingPathComponent:@"profile.plist"];
}

/**
 Get avatar filepath in Documents Directory
 
 @param ID - user ID
 @param filename - "xxxx.png"
 @return "Documents/.mkm/{address}/avatars/xxxx.png"
 */
static inline NSString *avatar_filepath(DIMID *ID, NSString * _Nullable filename, BOOL autoCreate) {
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

@implementation Facebook (Profile)

- (BOOL)saveProfile:(DIMProfile *)profile {
    // update memory cache
    [self cacheProfile:profile];
    
    NSString *path = profile_filepath(profile.ID, YES);
    if ([profile writeToBinaryFile:path]) {
        NSLog(@"profile %@ of %@ saved to %@", profile, profile.ID, path);
        return YES;
    } else {
        NSAssert(false, @"failed to save profile: %@, %@", profile.ID, profile);
        return NO;
    }
}

- (nullable DIMProfile *)loadProfileForID:(DIMID *)ID {
    NSString *path = profile_filepath(ID, NO);
    if (!file_exists(path)) {
        NSLog(@"profile not found: %@", path);
        return nil;
    }
    NSLog(@"loaded profile from %@", path);
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    return MKMProfileFromDictionary(dict);
}

- (void)cacheProfile:(DIMProfile *)profile {
    if (!profile) {
        return ;
    }
    [_profileTable setObject:profile forKey:profile.ID.address];
}

@end

NSString * const kNotificationName_AvatarUpdated = @"AvatarUpdated";

@implementation Facebook (Avatar)

- (BOOL)saveAvatar:(NSData *)data
              name:(nullable NSString *)filename
             forID:(DIMID *)ID {
    
    UIImage *image = [UIImage imageWithData:(NSData *)data];
    if (image.size.width < 32) {
        NSAssert(false, @"avatar image error: %@", data);
        return NO;
    }
    NSLog(@"avatar OK: %@", image);
    NSString *path = avatar_filepath(ID, filename, YES);
    [data writeToFile:path atomically:YES];
    // TODO: post notice 'AvatarUpdated'
    [NSNotificationCenter postNotificationName:kNotificationName_AvatarUpdated
                                        object:self
                                      userInfo:@{@"ID": ID}];
    return YES;
}

- (void)_downloadAvatar:(NSDictionary *)info {
    
    NSURL *url = [info objectForKey:@"URL"];
    NSString *path = [info objectForKey:@"Path"];
    DIMID *ID = [info objectForKey:@"ID"];
    
    // check
    static NSMutableArray *s_downloadings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_downloadings = [[NSMutableArray alloc] init];
    });
    if ([s_downloadings containsObject:url]) {
        NSLog(@"the job already exists: %@", url);
        return ;
    }
    [s_downloadings addObject:url];
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSLog(@"avatar downloaded (%lu bytes) from %@, save to %@", data.length, url, path);
    if (data.length > 0) {
        [self saveAvatar:data name:[path lastPathComponent] forID:ID];
    }
    
    [s_downloadings removeObject:url];
}

// Cache directory: "Documents/.mkm/{address}/avatar.png"
- (nullable UIImage *)loadAvatarWithURL:(NSString *)urlString forID:(DIMID *)ID {
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *filename = [url lastPathComponent];
    NSString *path = avatar_filepath(ID, filename, NO);
    
    if (file_exists(path)) {
        return [UIImage imageWithContentsOfFile:path];
    }
    // download in background
    [self performSelectorInBackground:@selector(_downloadAvatar:)
                           withObject:@{@"URL": url, @"Path": path, @"ID": ID}];
    return nil;
}

@end
