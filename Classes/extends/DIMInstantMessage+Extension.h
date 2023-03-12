//
//  DIMInstantMessage+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMP/DIMP.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMInstantMessage (Image)

@property (readonly, copy, nonatomic, nullable) UIImage *image;
@property (readonly, copy, nonatomic, nullable) UIImage *thumbnail;
@property (readonly, copy, nonatomic, nullable) NSData *audioData;

@end

NS_ASSUME_NONNULL_END
