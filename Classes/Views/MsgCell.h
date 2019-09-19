//
//  MsgCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Table view cell for Conversation History List
 */
@interface MsgCell : UITableViewCell {
    
    DIMInstantMessage *_msg;
}

@property (strong, nonatomic) DIMInstantMessage *msg;

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect;

@end

#pragma mark -

@interface SentMsgCell : MsgCell

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) IBOutlet UIImageView *messageImageView;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *infoButton;

@end

@interface ReceivedMsgCell : MsgCell

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *messageImageView;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;

@end

@interface CommandMsgCell : UITableViewCell {
    
    DIMInstantMessage *_msg;
}

@property (strong, nonatomic) DIMInstantMessage *msg;

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;

@end

@interface TimeCell : UITableViewCell {
    
    DIMInstantMessage *_msg;
}

@property (strong, nonatomic) DIMInstantMessage *msg;

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect;

@property (strong, nonatomic) UILabel *timeLabel;

@end

@interface GuideCell : UITableViewCell {

}

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect;

@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIButton *agreementButton;

@end

NS_ASSUME_NONNULL_END
