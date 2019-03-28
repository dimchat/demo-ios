//
//  DIMProfile+Extension.m
//  DIMClient
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImage+Extension.h"
#import "UIColor+Extension.h"

#import "DIMProfile+Extension.h"

@implementation DIMProfile (Extension)

- (UIImage *)avatarImageWithSize:(const CGSize)size {
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
