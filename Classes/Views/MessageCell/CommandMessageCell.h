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

@interface CommandMessageCell : MessageCell

@property (strong, nonatomic) DIMInstantMessage *msg;
@property (strong, nonatomic) UILabel *messageLabel;

@end

NS_ASSUME_NONNULL_END
