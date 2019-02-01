//
//  MsgCell.m
//  DIM
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSString+Extension.h"
#import "UIImage+Extension.h"

#import "MessageProcessor.h"

#import "MsgCell.h"

@implementation MsgCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    DIMEnvelope *env = self.msg.envelope;
    DIMMessageContent *content = self.msg.content;
    NSString *name = [NSString stringWithFormat:@"%@ [%@]", env.sender.name, NSStringFromDate(env.time)];
    NSString *text = content.text;
    
    UIEdgeInsets margins = self.layoutMargins;
    CGRect contentBounds = self.contentView.bounds;
    CGFloat maxWidth = contentBounds.size.width * 0.8;
    
    CGFloat space = 5.0;
    CGSize avatarSize = CGSizeMake(64, 64);
    CGFloat nameHeight = 20;
    
    // avatar
    CGRect avatarFrame;
    avatarFrame = CGRectMake(margins.left + contentBounds.origin.x,
                             margins.top + contentBounds.origin.y,
                             avatarSize.width,
                             avatarSize.height);
    self.avatarImageView.frame = avatarFrame;
    
    // name
    CGSize nameSize = CGSizeMake(maxWidth - avatarFrame.size.width - space * 3,
                                 nameHeight);
    nameSize = [name sizeWithFont:self.nameLabel.font maxSize:nameSize];
    CGRect nameFrame = CGRectMake(avatarFrame.origin.x + avatarFrame.size.width + space,
                                  avatarFrame.origin.y,
                                  nameSize.width,
                                  nameSize.height);
    self.nameLabel.frame = nameFrame;
    self.nameLabel.text = name;
    
    // message
    CGSize msgSize = CGSizeMake(maxWidth - avatarFrame.size.width - space * 3,
                                MAXFLOAT);
    msgSize = [text sizeWithFont:self.messageLabel.font maxSize:msgSize];
    CGRect msgFrame = CGRectMake(nameFrame.origin.x,
                                 nameFrame.origin.y + nameFrame.size.height + space,
                                 msgSize.width + 40,
                                 msgSize.height + 30);
    self.messageView.frame = msgFrame;
    self.messageLabel.frame = CGRectMake(20, 10, msgSize.width, msgSize.height);
    self.messageLabel.text = text;
    
    // resize content view
    CGRect frame = self.contentView.bounds;
    frame.size.height = msgFrame.origin.y + msgFrame.size.height;
    self.contentView.frame = frame;
    self.bounds = frame;
}

- (void)setMsg:(DKDInstantMessage *)msg {
    if (_msg != msg) {
        _msg = msg;
        [self setNeedsLayout];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
    
    // avatar
    UIImage *image = [UIImage imageNamed:@"[可爱]"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self.contentView addSubview:imageView];
    self.avatarImageView = imageView;
    
    // name
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:label];
    self.nameLabel = label;
    
    // message
    image = [UIImage imageNamed:@"message_receiver_background_normal"];
    imageView = [[UIImageView alloc] initWithImage:[image resizableImage]];
    //view.backgroundColor = [UIColor yellowColor];
    [self.contentView addSubview:imageView];
    self.messageView = imageView;
    
    UILabel *message = [[UILabel alloc] init];
    message.font = [UIFont systemFontOfSize:16];
    message.numberOfLines = 0;
    [imageView addSubview:message];
    self.messageLabel = message;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
