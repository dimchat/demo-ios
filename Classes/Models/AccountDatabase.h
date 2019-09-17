//
//  AccountDatabase.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kNotificationName_ContactsUpdated;

@interface AccountDatabase : DIMSocialNetworkDatabase

+ (instancetype)sharedInstance;

- (void)addStation:(DIMID *)stationID provider:(DIMServiceProvider *)sp;

@end

#pragma mark - Avatar

extern NSString * const kNotificationName_AvatarUpdated;

@interface AccountDatabase (Avatar)

- (BOOL)saveAvatar:(NSData *)data
              name:(nullable NSString *)filename
             forID:(DIMID *)ID;

- (nullable UIImage *)loadAvatarWithURL:(NSString *)urlString
                                  forID:(DIMID *)ID;

@end

#pragma mark - Register

@interface AccountDatabase (Register)

- (BOOL)saveMeta:(DIMMeta *)meta privateKey:(DIMPrivateKey *)SK forID:(DIMID *)ID;

- (BOOL)saveUserList:(NSArray<DIMLocalUser *> *)users withCurrentUser:(nullable DIMLocalUser *)curr;

@end

NS_ASSUME_NONNULL_END
