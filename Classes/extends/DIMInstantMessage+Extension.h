//
//  DIMInstantMessage+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMInstantMessage (Extension)

@property (readonly, copy, nonatomic, nullable) UIImage *image;

@end

NS_ASSUME_NONNULL_END
