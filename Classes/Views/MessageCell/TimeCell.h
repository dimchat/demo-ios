//
//  MsgCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface TimeCell : UITableViewCell

+ (CGSize)sizeWithMessage:(DIMInstantMessage )message bounds:(CGRect)rect;

-(void)setTime:(NSTimeInterval)timestamp;

@end

NS_ASSUME_NONNULL_END
