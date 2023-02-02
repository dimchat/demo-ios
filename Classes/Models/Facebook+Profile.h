//
//  Facebook+Profile.h
//  Sechat
//
//  Created by Albert Moky on 2019/6/27.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kNotificationName_AvatarUpdated;

@interface DIMFacebook (Avatar)

- (BOOL)saveAvatar:(NSData *)data
              name:(nullable NSString *)filename
             forID:(id<MKMID>)ID;

- (nullable UIImage *)loadAvatarWithURL:(NSString *)urlString
                                  forID:(id<MKMID>)ID;

@end

NS_ASSUME_NONNULL_END
