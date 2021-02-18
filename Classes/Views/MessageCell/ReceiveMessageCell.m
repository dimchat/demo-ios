//
//  MsgCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Extension.h"
#import "NSString+Extension.h"
#import "UIImage+Extension.h"
#import "UIImageView+Extension.h"
#import "UIButton+Extension.h"
#import "UIView+Extension.h"
#import "UIStoryboard+Extension.h"
#import "Facebook+Profile.h"
#import "DIMProfile+Extension.h"
#import "DIMInstantMessage+Extension.h"

#import "WebViewController.h"
#import "MessageDatabase.h"
#import "ZoomInViewController.h"
#import "ReceiveMessageCell.h"

@implementation ReceiveMessageCell

+ (CGSize)sizeWithMessage:(DIMInstantMessage)iMsg bounds:(CGRect)rect showName:(BOOL)showName{
    
    NSString *text = nil;
    if (iMsg.content.type == DKDContentType_Text) {
        text = [(DIMTextContent *)iMsg.content text];
    }
    
    CGFloat cellWidth = rect.size.width;
    CGFloat msgWidth = cellWidth * 0.618;
    UIEdgeInsets edges = UIEdgeInsetsMake(10, 20, 10, 20);
    CGSize size;
    
    UIImage *image = [(DKDInstantMessage *)iMsg image];
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
    
    if(showName){
        cellHeight += 12.0;
    }
    
    return CGSizeMake(cellWidth, cellHeight);
}

+ (CGSize)sizeWithMessage:(DIMInstantMessage)iMsg bounds:(CGRect)rect {
    return [ReceiveMessageCell sizeWithMessage:iMsg bounds:rect showName:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = 44.0;
    CGFloat width = 44.0;
    CGFloat y = 8.0;
    CGFloat x = 8.0;
    
    self.avatarImageView.frame = CGRectMake(x, y, width, height);
    self.avatarImageView.layer.cornerRadius = width / 2.0;
    self.avatarImageView.layer.masksToBounds = YES;
    
    if(self.showName){
        self.nameLabel.hidden = NO;
        x = self.avatarImageView.frame.origin.x + self.avatarImageView.frame.size.width + 15.0;
        width = self.contentView.bounds.size.width - x;
        height = 14.0;
        self.nameLabel.frame = CGRectMake(x, y, width, height);
    }else{
        self.nameLabel.hidden = YES;
        self.nameLabel.frame = CGRectZero;
    }
    
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
        UIImage *image = [(DKDInstantMessage *)self.message image];
        if (image.size.width > max_width) {
            CGFloat ratio = max_width / image.size.width;
            contentSize = CGSizeMake(image.size.width * ratio, image.size.height * ratio);
        } else {
            contentSize = image.size;
        }
        
        //Show Image
        x = self.avatarImageView.frame.origin.x + self.avatarImageView.frame.size.width + 10.0;
        y = self.avatarImageView.frame.origin.y + 5.0 + self.nameLabel.bounds.size.height;
        width = contentSize.width;
        height = contentSize.height;
        self.picImageView.frame = CGRectMake(x, y, width, height);
        
    } else if (self.message.content.type == DKDContentType_Audio) {
           
           width = 160.0;
           
           contentSize = CGSizeMake(messageMaxWidth - edges.left - edges.right, MAXFLOAT);
           contentSize = [text sizeWithFont:font maxSize:contentSize];
           contentSize.width = width;
           
           CGSize imageSize = CGSizeMake(contentSize.width + edges.left + edges.right,
                                         contentSize.height + edges.top + edges.bottom);
           x = self.avatarImageView.frame.origin.x + self.avatarImageView.frame.size.width + 10.0;
           y = self.avatarImageView.frame.origin.y + 3.0 + self.nameLabel.bounds.size.height;
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
        x = self.avatarImageView.frame.origin.x + self.avatarImageView.frame.size.width + 10.0;
        y = self.avatarImageView.frame.origin.y + 3.0 + self.nameLabel.bounds.size.height;
        width = imageSize.width;
        height = imageSize.height;
        self.messageImageView.frame = CGRectMake(x, y, width, height);
        
        x = x + edges.left + 5.0;
        y = y + edges.top;
        width = contentSize.width;
        height = contentSize.height;
        self.messageLabel.frame = CGRectMake(x, y, width, height);
        
    }
}

@end
