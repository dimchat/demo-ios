//
//  SentMessageCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface CommandMessageCell : UITableViewCell

@property (nonatomic, assign) id<MessageCellDelegate>delegate;
@property (strong, nonatomic) DIMInstantMessage *msg;
@property (strong, nonatomic) UILabel *messageLabel;

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)message bounds:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
