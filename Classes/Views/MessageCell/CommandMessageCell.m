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
#import "UIButton+Extension.h"
#import "UIView+Extension.h"
#import "UIStoryboard+Extension.h"
#import "DIMProfile+Extension.h"
#import "DIMInstantMessage+Extension.h"
#import "WebViewController.h"
#import "User.h"
#import "MessageProcessor.h"
#import "ZoomInViewController.h"
#import "CommandMessageCell.h"

@implementation CommandMessageCell

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect {
    
    NSString *text = [iMsg.content objectForKey:@"text"];
    
    CGFloat cellWidth = rect.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 10, 10, 10);
    
    CGSize size = CGSizeMake(msgWidth - edges.left - edges.right,
                             MAXFLOAT);
    UIFont *font = [UIFont systemFontOfSize:14];
    size = [text sizeWithFont:font maxSize:size];
    CGFloat cellHeight = size.height + edges.top + edges.bottom + 24;
    return CGSizeMake(cellWidth, cellHeight);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat cellWidth = self.bounds.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 10, 10, 10);
    
    UILabel *timeLabel = [self timeLabel];
    UILabel *messageLabel = [self messageLabel];
    
    CGRect timeFrame = timeLabel.frame;
    
    NSString *text = messageLabel.text;
    if (text.length > 0) {
        UIFont *font = messageLabel.font;
        CGSize size = CGSizeMake(msgWidth, MAXFLOAT);
        size = [text sizeWithFont:font maxSize:size];
        size.width += edges.left + edges.right;
        size.height += edges.top + edges.bottom;
        CGRect frame = CGRectMake((cellWidth - size.width) * 0.5,
                                  timeFrame.origin.y + timeFrame.size.height,
                                  size.width, size.height);
        messageLabel.frame = frame;
    }
    
    // resize content view
    CGRect msgFrame = messageLabel.frame;
    CGFloat cellHeight = msgFrame.origin.y + msgFrame.size.height + edges.bottom;
    CGRect rect = CGRectMake(0, 0, cellWidth, cellHeight);
    self.bounds = rect;
    self.contentView.frame = rect;
}

- (void)setMsg:(DIMInstantMessage *)msg {
    if (![_msg isEqual:msg]) {
        _msg = msg;
        
        CGFloat cellWidth = self.bounds.size.width;
        CGFloat msgWidth = cellWidth * 0.618;
        
        // time
        NSString *time = @"";
        UILabel *timeLabel = [self timeLabel];
        if (time.length > 0) {
            timeLabel.text = time;
            // resize
            UIFont *font = timeLabel.font;
            CGSize size = CGSizeMake(msgWidth, MAXFLOAT);
            size = [time sizeWithFont:font maxSize:size];
            size = CGSizeMake(size.width + 16, 16);
            CGRect rect = CGRectMake(0, 0, size.width, size.height);
            timeLabel.bounds = rect;
            [timeLabel roundedCorner];
            timeLabel.hidden = NO;
        } else {
            timeLabel.bounds = CGRectMake(0, 0, 0, 0);
            timeLabel.text = @"";
            timeLabel.hidden = YES;
        }
        
        // message
        NSString *text = [msg.content objectForKey:@"text"];
        UILabel *messageLabel = [self messageLabel];
        messageLabel.text = text;
        
        [self setNeedsLayout];
    }
}

@end
