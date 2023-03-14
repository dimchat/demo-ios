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
#import "DIMMessageBuilder.h"

#import "WebViewController.h"
#import "MessageDatabase.h"
#import "ZoomInViewController.h"
#import "CommandMessageCell.h"

@implementation CommandMessageCell

+ (CGSize)sizeWithMessage:(id<DKDInstantMessage>)iMsg bounds:(CGRect)rect {
    
    //NSString *text = [iMsg.content objectForKey:@"text"];
    id<MKMID> sender = iMsg.envelope.sender;
    DIMCommand *content = (DIMCommand *)iMsg.content;
    NSString *text = [content messageWithSender:sender];
    
    CGFloat cellWidth = rect.size.width;
    CGFloat msgWidth = [UIScreen mainScreen].bounds.size.width;
    UIEdgeInsets edges = UIEdgeInsetsMake(0, 10, 0, 10);
    
    CGSize size = CGSizeMake(msgWidth - edges.left - edges.right,
                             MAXFLOAT);
    UIFont *font = [UIFont systemFontOfSize:12];
    size = [text sizeWithFont:font maxSize:size];
    CGFloat cellHeight = size.height + edges.top + edges.bottom + 10.0;
    return CGSizeMake(cellWidth, cellHeight);
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.font = [UIFont systemFontOfSize:12.0];
        self.messageLabel.textColor = [UIColor lightGrayColor];
        self.messageLabel.numberOfLines = -1;
        [self.contentView addSubview:self.messageLabel];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat x = 10.0;
    CGFloat y = 5.0;
    CGFloat width = self.contentView.bounds.size.width - x * 2;
    CGFloat height = self.contentView.bounds.size.height - 5.0;
    
    self.messageLabel.frame = CGRectMake(x, y, width, height);
}

- (void)setMsg:(id<DKDInstantMessage>)msg {
    if (![_msg isEqual:msg]) {
        _msg = msg;
        
        // message
        id<MKMID> sender = msg.envelope.sender;
        DIMCommand *content = (DIMCommand *)msg.content;
        NSString *text = [content messageWithSender:sender];
        
        self.messageLabel.text = text;
        
        [self setNeedsLayout];
    }
}

@end
