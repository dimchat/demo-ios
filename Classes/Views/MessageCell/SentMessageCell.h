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

@interface SentMessageCell : MessageCell

@property (strong, nonatomic) DIMInstantMessage *msg;
@property (strong, nonatomic) UIImageView *avatarImageView;
@property (strong, nonatomic) UIImageView *messageImageView;
@property (strong, nonatomic) UIImageView *picImageView;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIButton *infoButton;

@end

NS_ASSUME_NONNULL_END
