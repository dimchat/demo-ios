//
//  MsgCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSString+Extension.h"
#import "UIImage+Extension.h"
#import "UIImageView+Extension.h"
#import "DIMProfile+Extension.h"

#import "User.h"

#import "MessageProcessor.h"

#import "MsgCell.h"

@implementation MsgCell

+ (CGSize)sizeWithMessage:(DKDInstantMessage *)iMsg bounds:(CGRect)rect {
    NSString *text = iMsg.content.text;
    CGFloat cellWidth = rect.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    
    CGSize size = CGSizeMake(msgWidth - edges.left - edges.right,
                             MAXFLOAT);
    UIFont *font = [UIFont systemFontOfSize:16];
    size = [text sizeWithFont:font maxSize:size];
    CGFloat cellHeight = size.height + edges.top + edges.bottom + 40;
    if (cellHeight < 80) {
        cellHeight = 80;
    }
    return CGSizeMake(cellWidth, cellHeight);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    id cell = self;
    //UILabel *timeLabel = [cell timeLabel];
    //UIImageView *avatarImageView = [cell avatarImageView];
    UIImageView *messageImageView = [cell messageImageView];
    UILabel *messageLabel = [cell messageLabel];
    
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    
    // message
    UIFont *font = messageLabel.font;
    NSString *text = messageLabel.text;
    CGSize size = CGSizeMake(msgWidth, MAXFLOAT);
    size = [text sizeWithFont:font maxSize:size];
    
    CGRect imageFrame = messageImageView.frame;
    imageFrame.size = CGSizeMake(size.width + edges.left + edges.right,
                                 size.height + edges.top + edges.bottom);
    CGRect labelFrame = CGRectMake(imageFrame.origin.x + edges.left,
                                   imageFrame.origin.y + edges.top,
                                   size.width, size.height);
    messageImageView.frame = imageFrame;
    messageLabel.frame = labelFrame;
    
    // resize content view
    CGFloat cellHeight = imageFrame.origin.y + imageFrame.size.height;
    if (cellHeight < 80) {
        cellHeight = 80;
    }
    CGRect rect = CGRectMake(0, 0, cellWidth, cellHeight);
    self.bounds = rect;
    self.contentView.frame = rect;
}

- (void)setMsg:(DKDInstantMessage *)msg {
    if (![_msg isEqual:msg]) {
        _msg = msg;
        
        id cell = self;
        UILabel *timeLabel = [cell timeLabel];
        UIImageView *avatarImageView = [cell avatarImageView];
        UILabel *messageLabel = [cell messageLabel];
        
        DIMEnvelope *env = msg.envelope;
        const DIMID *sender = [DIMID IDWithID:env.sender];
        DIMMessageContent *content = msg.content;
        DIMProfile *profile = DIMProfileForID(sender);
        
        // time
        NSString *time = [msg objectForKey:@"timeTag"];
        if (time.length > 0) {
            timeLabel.text = time;
            // resize
            UIFont *font = timeLabel.font;
            CGSize size = CGSizeMake(200, MAXFLOAT);
            size = [time sizeWithFont:font maxSize:size];
            size = CGSizeMake(size.width + 16, 16);
            CGRect rect = CGRectMake(0, 0,
                                     size.width, size.height);
            timeLabel.bounds = rect;
            [timeLabel roundedCorner];
        } else {
            timeLabel.bounds = CGRectMake(0, 0, 0, 0);
            timeLabel.text = @"";
        }
        
        // avatar
        CGRect avatarFrame = avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
        [avatarImageView setImage:image];
        
        // message
        messageLabel.text = content.text;
        
        [self setNeedsLayout];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    id cell = self;
    // avatar
    [[cell avatarImageView] roundedCorner];
    
    // message
    [cell messageImageView].image = [[cell messageImageView].image resizableImage];
}

@end

#pragma mark -

@implementation SentMsgCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    CGFloat space = 5;
    
    CGRect avatarFrame = _avatarImageView.frame;
    CGRect msgImageFrame = _messageImageView.frame;
    CGRect msgLabelFrame = _messageLabel.frame;
    
    // adjust position of message box
    msgImageFrame.origin.x = avatarFrame.origin.x - space - msgImageFrame.size.width;
    msgLabelFrame.origin.x = msgImageFrame.origin.x + edges.left;
    
    _messageImageView.frame = msgImageFrame;
    _messageLabel.frame = msgLabelFrame;
}

@end

@implementation ReceivedMsgCell

- (void)setMsg:(DKDInstantMessage *)msg {
    [super setMsg:msg];
    
    DIMEnvelope *env = msg.envelope;
    const DIMID *sender = [DIMID IDWithID:env.sender];
    
    // name
    _nameLabel.text = readable_name(sender);
}

@end
