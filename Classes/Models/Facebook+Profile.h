//
//  Facebook+Profile.h
//  Sechat
//
//  Created by Albert Moky on 2019/6/27.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Facebook.h"

NS_ASSUME_NONNULL_BEGIN

@interface Facebook (Profile)

- (BOOL)saveProfile:(DIMProfile *)profile;
- (nullable DIMProfile *)loadProfileForID:(DIMID *)ID;
- (BOOL)cacheProfile:(DIMProfile *)profile;

@end

extern NSString * const kNotificationName_AvatarUpdated;

@interface Facebook (Avatar)

- (BOOL)saveAvatar:(NSData *)data
              name:(nullable NSString *)filename
             forID:(DIMID *)ID;

- (nullable UIImage *)loadAvatarWithURL:(NSString *)urlString
                                  forID:(DIMID *)ID;

@end

NS_ASSUME_NONNULL_END
