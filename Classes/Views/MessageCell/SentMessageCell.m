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
#import "MessageDatabase.h"
#import "ZoomInViewController.h"
#import "SentMessageCell.h"

@implementation SentMessageCell

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect {
    NSString *text = nil;
    if (iMsg.content.type == DKDContentType_Text) {
        text = [(DIMTextContent *)iMsg.content text];
    }
    
    CGFloat cellWidth = rect.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    CGSize size;
    
    UIImage *image = iMsg.image;
    if (image) {
        size = [UIScreen mainScreen].bounds.size;
        CGFloat max_width = MIN(size.width, size.height) * 0.382;
        if (image.size.width > max_width) {
            CGFloat ratio = max_width / image.size.width;
            size = CGSizeMake(image.size.width * ratio, image.size.height * ratio);
        } else {
            size = image.size;
        }
    } else {
        UIFont *font = [UIFont systemFontOfSize:16];
        size = CGSizeMake(msgWidth - edges.left - edges.right, MAXFLOAT);
        size = [text sizeWithFont:font maxSize:size];
    }
    
    CGFloat cellHeight = size.height + edges.top + edges.bottom + 16;
    
    if (cellHeight < 55) {
        cellHeight = 55;
    }
    return CGSizeMake(cellWidth, cellHeight);
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        UIImage *chatBackgroundImage = [UIImage imageNamed:@"sender_bubble"];
        UIEdgeInsets insets = UIEdgeInsetsMake(17.0, 20.0, 17.0, 28.0);
        self.messageImageView.image = [chatBackgroundImage resizableImageWithCapInsets:insets];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = 44.0;
    CGFloat width = 44.0;
    CGFloat y = 8.0;
    CGFloat x = self.contentView.bounds.size.width - 8.0 - width;
    
    self.avatarImageView.frame = CGRectMake(x, y, width, height);
    self.avatarImageView.layer.cornerRadius = width / 2.0;
    self.avatarImageView.layer.masksToBounds = YES;
    
    CGFloat messageMaxWidth = self.contentView.bounds.size.width * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    
    // message
    UIFont *font = self.messageLabel.font;
    NSString *text = self.messageLabel.text;
    CGSize contentSize;
    
    if (self.message.content.type == DKDContentType_Image) {
        
        self.messageImageView.hidden = YES;
        self.messageLabel.hidden = YES;
        self.picImageView.hidden = NO;
        
        contentSize = [UIScreen mainScreen].bounds.size;
        CGFloat max_width = MIN(contentSize.width, contentSize.height) * 0.382;
        if (self.message.image.size.width > max_width) {
            CGFloat ratio = max_width / self.message.image.size.width;
            contentSize = CGSizeMake(self.message.image.size.width * ratio, self.message.image.size.height * ratio);
        } else {
            contentSize = self.message.image.size;
        }
        
        //Show Image
        x = self.avatarImageView.frame.origin.x - 10.0 - contentSize.width;
        y = self.avatarImageView.frame.origin.y + 5.0;
        width = contentSize.width;
        height = contentSize.height;
        self.picImageView.frame = CGRectMake(x, y, width, height);
        
    } else if(self.message.content.type == DKDContentType_Audio) {
        
        width = 160.0;
        
        contentSize = CGSizeMake(messageMaxWidth - edges.left - edges.right, MAXFLOAT);
        contentSize = [text sizeWithFont:font maxSize:contentSize];
        contentSize.width = width;
        
        CGSize imageSize = CGSizeMake(contentSize.width + edges.left + edges.right,
                                      contentSize.height + edges.top + edges.bottom);
        x = self.avatarImageView.frame.origin.x - 10.0 - imageSize.width;
        y = self.avatarImageView.frame.origin.y + 3.0;
        width = imageSize.width;
        height = imageSize.height;
        self.messageImageView.frame = CGRectMake(x, y, width, height);
        
        x = x + edges.left - 5.0;
        y = y + edges.top;
        width = contentSize.width;
        height = contentSize.height;
        self.audioButton.frame = CGRectMake(x, y, width, height);
        
    } else {
        
        self.messageImageView.hidden = NO;
        self.messageLabel.hidden = NO;
        self.picImageView.hidden = YES;
        
        contentSize = CGSizeMake(messageMaxWidth - edges.left - edges.right, MAXFLOAT);
        contentSize = [text sizeWithFont:font maxSize:contentSize];
        
        CGSize imageSize = CGSizeMake(contentSize.width + edges.left + edges.right,
                                      contentSize.height + edges.top + edges.bottom);
        x = self.avatarImageView.frame.origin.x - 10.0 - imageSize.width;
        y = self.avatarImageView.frame.origin.y + 3.0;
        width = imageSize.width;
        height = imageSize.height;
        self.messageImageView.frame = CGRectMake(x, y, width, height);
        
        x = x + edges.left - 5.0;
        y = y + edges.top;
        width = contentSize.width;
        height = contentSize.height;
        self.messageLabel.frame = CGRectMake(x, y, width, height);
    }
}

@end
