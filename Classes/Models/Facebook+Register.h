//
//  Facebook+Register.h
//  DIMClient
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Facebook.h"

NS_ASSUME_NONNULL_BEGIN

@interface Facebook (Register)

- (BOOL)saveMeta:(DIMMeta *)meta privateKey:(DIMPrivateKey *)SK forID:(DIMID *)ID;

- (NSArray<DIMID *> *)scanUserIDList;

- (BOOL)saveUserIDList:(NSArray<DIMID *> *)users withCurrentID:(nullable DIMID *)curr;
- (BOOL)saveUserList:(NSArray<DIMUser *> *)users withCurrentUser:(nullable DIMUser *)curr;

- (BOOL)removeUser:(DIMUser *)user;

- (BOOL)saveProfile:(DIMProfile *)profile forID:(DIMID *)ID;
- (nullable DIMProfile *)loadProfileForID:(DIMID *)ID;

- (BOOL)saveMembers:(NSArray<DIMID *> *)list withGroupID:(DIMID *)grp;
- (NSArray<DIMID *> *)loadMembersWithGroupID:(DIMID *)grp;

@end

#pragma mark - Avatar

extern NSString * const kNotificationName_AvatarUpdated;

@interface Facebook (Avatar)

- (BOOL)saveAvatar:(NSData *)data
              name:(nullable NSString *)filename
             forID:(DIMID *)ID;

- (nullable UIImage *)loadAvatarWithURL:(NSString *)urlString
                                  forID:(DIMID *)ID;

@end

NS_ASSUME_NONNULL_END
