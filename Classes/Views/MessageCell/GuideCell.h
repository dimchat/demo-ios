//
//  MsgCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DIMClient/DIMClient.h>
#import "MessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface GuideCell : UITableViewCell

@property (nonatomic, assign) id<MessageCellDelegate>delegate;

+ (CGSize)sizeWithMessage:(id<DKDInstantMessage>)message bounds:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
