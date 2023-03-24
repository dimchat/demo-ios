//
//  DIMProfile+Extension.h
//  DIMP
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMVisa (Extension)

// user.avatar
- (UIImage *)avatarImageWithSize:(const CGSize)size;

@end

@interface DIMBulletin (Extension)

// group.logo
- (UIImage *)logoImageWithSize:(const CGSize)size;

@end

NS_ASSUME_NONNULL_END
