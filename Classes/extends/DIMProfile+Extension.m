//
//  DIMProfile+Extension.m
//  DIMClient
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"

#import "UIImage+Extension.h"
#import "UIColor+Extension.h"

#import "Client.h"

#import "DIMProfile+Extension.h"

const NSString *kNotificationName_AvatarUpdated = @"AvatarUpdated";

@implementation DIMProfile (Extension)

- (BOOL)saveAvatar:(const NSData *)data name:(nullable const NSString *)filename {
    UIImage *image = [UIImage imageWithData:(NSData *)data];
    if (image.size.width < 32) {
        NSAssert(false, @"image error: %@", data);
        return NO;
    }
    NSString *ext = [filename pathExtension];
    if (ext.length == 0) {
        data = UIImagePNGRepresentation(image);
        ext = @"png";
    }
    NSLog(@"avatar OK: %@", image);
    NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/avatar.%@", document_directory(), self.ID.address, ext];
    [data writeToFile:path atomically:YES];
    // TODO: post notice 'AvatarUpdated'
    [NSNotificationCenter postNotificationName:kNotificationName_AvatarUpdated object:self];
    return YES;
}

- (void)_downloadAvatar:(NSDictionary *)urls {
    NSURL *url = [urls objectForKey:@"URL"];
    NSString *path = [urls objectForKey:@"Path"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSLog(@"avatar downloaded (%lu bytes) from %@, save to %@", data.length, url, path);
    [self saveAvatar:data name:[path lastPathComponent]];
}

// Cache directory: "Documents/.mkm/{address}/avatar.png"
- (UIImage *)_loadAvatarWithURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *ext = [url pathExtension];
    NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/avatar.%@", document_directory(), self.ID.address, ext];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        return [UIImage imageWithContentsOfFile:path];
    }
    // download in background
    [self performSelectorInBackground:@selector(_downloadAvatar:) withObject:@{@"URL": url, @"Path": path}];
    return nil;
}

- (UIImage *)avatarImageWithSize:(const CGSize)size {
    UIImage *image = nil;
    NSString *avatar = self.avatar;
    if (avatar) {
        if ([avatar containsString:@"://"]) {
            image = [self _loadAvatarWithURL:avatar];
        } else {
            image = [UIImage imageNamed:avatar];
        }
    }
    if (!image) {
        NSString *name = self.name;
        if (name.length == 0) {
            name = self.ID.name;
            if (name.length == 0) {
                name = @"Đ"; // BTC Address: ฿
            }
        }
        NSString *text = [name substringToIndex:1];
        UIColor *textColor = [UIColor whiteColor];
        UIImage *bgImage = [UIImage imageNamed:@"avatar-bg"];
        if (bgImage) {
            image = [UIImage imageWithText:text size:size color:textColor backgroundImage:bgImage];
        } else {
            UIColor *bgColor = [UIColor colorWithHexString:@"1F1F0A"];
            image = [UIImage imageWithText:text size:size color:textColor backgroundColor:bgColor];
        }
    }
    return image;
}

- (UIImage *)logoImageWithSize:(const CGSize)size {
    UIImage *image = nil;
    NSString *avatar = self.avatar;
    if (avatar) {
        if ([avatar containsString:@"://"]) {
            image = [UIImage imageWithURLString:avatar];
        } else {
            image = [UIImage imageNamed:avatar];
        }
    }
    if (!image) {
        NSArray<const DIMID *> *members = DIMGroupWithID(self.ID).members;
        if (members.count > 0) {
            CGSize tileSize;
            if (members.count > 4) {
                tileSize = CGSizeMake(size.width / 3 - 2, size.height / 3 - 2);
            } else {
                tileSize = CGSizeMake(size.width / 2 - 2, size.height / 2 - 2);
            }
            NSMutableArray<UIImage *> *mArray;
            mArray = [[NSMutableArray alloc] initWithCapacity:members.count];
            for (const DIMID *ID in members) {
                image = [DIMProfileForID(ID) avatarImageWithSize:tileSize];
                if (image) {
                    [mArray addObject:image];
                    if (mArray.count >= 9) {
                        break;
                    }
                }
            }
            UIColor *bgColor = [UIColor colorWithHexString:@"E0E0F5"];
            image = [UIImage tiledImages:mArray size:size backgroundColor:bgColor];
        }
    }
    if (!image) {
        NSString *name = self.name;
        if (name.length == 0) {
            name = self.ID.name;
            if (name.length == 0) {
                name = @"Đ"; // BTC Address: ฿
            }
        }
        NSString *text = [name substringToIndex:1];
        //text = [NSString stringWithFormat:@"[%@]", text];
        UIColor *textColor = [UIColor whiteColor];
        UIColor *bgColor = [UIColor colorWithHexString:@"E0E0F5"];
        image = [UIImage imageWithText:text size:size color:textColor backgroundColor:bgColor];
    }
    return image;
}

@end
