//
//  ConversationCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BadgeView.h"
#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Table view cell for Conversation List (Secure Chat History)
 */
@interface ConversationCell : UITableViewCell

@property (strong, nonatomic) UIImageView *avatarImageView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *lastMsgLabel;
@property (strong, nonatomic) UILabel *lastTimeLabel;
@property (strong, nonatomic) BadgeView *badgeView;

@property (strong, nonatomic) DIMConversation *conversation;

@end

NS_ASSUME_NONNULL_END
