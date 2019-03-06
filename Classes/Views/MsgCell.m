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

@end

#pragma mark -

@implementation SentMsgCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    CGFloat space = 5;
    
    CGRect frame;
    
    // message
    CGSize size = CGSizeMake(msgWidth - edges.left - edges.right,
                             MAXFLOAT);
    UIFont *font = _messageLabel.font;
    NSString *text = _messageLabel.text;
    size = [text sizeWithFont:font maxSize:size];
    
    frame = _messageImageView.frame;
    frame.size = CGSizeMake(size.width + edges.left + edges.right,
                            size.height + edges.top + edges.bottom);
    frame.origin.x = _avatarImageView.frame.origin.x - space - frame.size.width;
    _messageImageView.frame = frame;
    _messageLabel.frame = CGRectMake(frame.origin.x + edges.left,
                                     frame.origin.y + edges.top,
                                     size.width,
                                     size.height);
    
    // resize content view
    CGFloat cellHeight = frame.origin.y + frame.size.height;
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
        
        DIMEnvelope *env = _msg.envelope;
        DIMMessageContent *content = _msg.content;
        DIMProfile *profile = MKMProfileForID(env.sender);
        
        // avatar
        CGRect avatarFrame = _avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
        [_avatarImageView setImage:image];
        
        // message
        _messageLabel.text = content.text;
        
        [self setNeedsLayout];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // avatar
    [_avatarImageView roundedCorner];
    
    // message
    _messageImageView.image = [_messageImageView.image resizableImage];
}

@end

@implementation ReceivedMsgCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    
    CGRect frame;
    
    // name
    frame = _nameLabel.frame;
    frame.size.width = msgWidth;
    _nameLabel.frame = frame;
    
    // message
    CGSize size = CGSizeMake(msgWidth - edges.left - edges.right,
                                MAXFLOAT);
    UIFont *font = _messageLabel.font;
    NSString *text = _messageLabel.text;
    size = [text sizeWithFont:font maxSize:size];
    
    frame = _messageImageView.frame;
    frame = CGRectMake(frame.origin.x,
                       frame.origin.y,
                       size.width + edges.left + edges.right,
                       size.height + edges.top + edges.bottom);
    _messageImageView.frame = frame;
    _messageLabel.frame = CGRectMake(frame.origin.x + edges.left,
                                     frame.origin.y + edges.top,
                                     size.width,
                                     size.height);

    // resize content view
    CGFloat cellHeight = frame.origin.y + frame.size.height;
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
        
        DIMEnvelope *env = _msg.envelope;
        DIMMessageContent *content = _msg.content;
        DIMProfile *profile = MKMProfileForID(env.sender);
        
        // avatar
        CGRect avatarFrame = _avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
        [_avatarImageView setImage:image];
        
        // name
        _nameLabel.text = readable_name(env.sender);
        
        // message
        _messageLabel.text = content.text;
        
        [self setNeedsLayout];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // avatar
    [_avatarImageView roundedCorner];
    
    // message
    _messageImageView.image = [_messageImageView.image resizableImage];
}

@end
