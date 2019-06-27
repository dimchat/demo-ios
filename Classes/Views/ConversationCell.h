//
//  ConversationCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Table view cell for Conversation List (Secure Chat History)
 */
@interface ConversationCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastMsgLabel;
@property (strong, nonatomic) IBOutlet UILabel *lastTimeLabel;

@property (strong, nonatomic) DIMConversation *conversation;

@end

NS_ASSUME_NONNULL_END
