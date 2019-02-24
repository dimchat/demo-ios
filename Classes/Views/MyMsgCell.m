//
//  MyMsgCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImage+Extension.h"

#import "MessageProcessor.h"

#import "MyMsgCell.h"

@implementation MyMsgCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    DIMEnvelope *env = self.msg.envelope;
    
    UIEdgeInsets margins = self.layoutMargins;
    CGRect contentBounds = self.contentView.bounds;
    //CGFloat maxWidth = contentBounds.size.width * 0.8;
    
    CGFloat space = 5.0;
    CGSize avatarSize = CGSizeMake(40, 40);
    //CGFloat nameHeight = 20;
    
    // avatar
    CGRect avatarFrame = self.avatarImageView.frame;
    avatarFrame.origin.x = contentBounds.size.width - margins.right - avatarSize.width - space * 2;
    self.avatarImageView.frame = avatarFrame;
    
    // name
    CGRect nameFrame = self.nameLabel.frame;
    nameFrame.origin.x = avatarFrame.origin.x - space - nameFrame.size.width;
    self.nameLabel.frame = nameFrame;
    self.nameLabel.text = [NSString stringWithFormat:@"[%@] %@", NSStringFromDate(env.time), env.sender.name];
    
    // message
    CGRect msgFrame = self.messageView.frame;
    msgFrame.origin.x = avatarFrame.origin.x - space - msgFrame.size.width;
    self.messageView.frame = msgFrame;
    
    UIImage *image = [UIImage imageNamed:@"message_sender_background_normal"];
    [self.messageView setImage:[image resizableImage]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
