//
//  MsgCell.h
//  DIM
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface MsgCell : UITableViewCell

@property (strong, nonatomic) DIMInstantMessage *msg;

@property (strong, nonatomic) UIImageView *avatarImageView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIImageView *messageView;

@end

NS_ASSUME_NONNULL_END
