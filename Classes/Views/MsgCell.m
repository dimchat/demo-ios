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

#import "User.h"

#import "MessageProcessor.h"

#import "ZoomInViewController.h"

#import "MsgCell.h"

@interface MsgCell ()

@property (strong, nonatomic) UIImage *picture;

@end

@implementation MsgCell

+ (CGSize)sizeWithMessage:(DKDInstantMessage *)iMsg bounds:(CGRect)rect {
    NSString *text = iMsg.content.text;
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
    
    NSString *time = [iMsg objectForKey:@"timeTag"];
    if (time.length > 0) {
        cellHeight += 20;
    }
    
    if (cellHeight < 80) {
        cellHeight = 80;
    }
    return CGSizeMake(cellWidth, cellHeight);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (UIImage *)picture {
    if (!_picture) {
        _picture = _msg.image;
    }
    return _picture;
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
    CGSize size;
    
    if (_picture) {
        size = [UIScreen mainScreen].bounds.size;
        CGFloat max_width = MIN(size.width, size.height) * 0.382;
        if (_picture.size.width > max_width) {
            CGFloat ratio = max_width / _picture.size.width;
            size = CGSizeMake(_picture.size.width * ratio, _picture.size.height * ratio);
        } else {
            size = _picture.size;
        }
    } else {
        size = CGSizeMake(msgWidth - edges.left - edges.right, MAXFLOAT);
        size = [text sizeWithFont:font maxSize:size];
    }
    
    CGRect imageFrame = messageImageView.frame;
    imageFrame.size = CGSizeMake(size.width + edges.left + edges.right,
                                 size.height + edges.top + edges.bottom);
    CGRect labelFrame = CGRectMake(imageFrame.origin.x + edges.left,
                                   imageFrame.origin.y + edges.top,
                                   size.width + 16, size.height);
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
        
        self.picture = msg.image;
        
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
        switch (content.type) {
            case DIMMessageType_Text: {
                messageLabel.text = content.text;
                
                [messageLabel addDoubleClickTarget:self action:@selector(zoomIn)];
            }
                break;
                
            case DIMMessageType_Image: {
                if (_picture) {
                    CGSize size = [UIScreen mainScreen].bounds.size;
                    CGFloat max_width = MIN(size.width, size.height) * 0.382;
                    
                    if (_picture.size.width > max_width) {
                        CGFloat ratio = max_width / _picture.size.width;
                        size = CGSizeMake(_picture.size.width * ratio, _picture.size.height * ratio);
                    } else {
                        size = _picture.size;
                    }
                    
                    NSTextAttachment *att = [[NSTextAttachment alloc] init];
                    att.image = _picture;
                    att.bounds = CGRectMake(0, 0, size.width, size.height);
                    NSAttributedString *as = [NSAttributedString attributedStringWithAttachment:att];
                    messageLabel.attributedText = as;
                    messageLabel.bounds = CGRectMake(0, 0, size.width, size.height);
                } else {
                    messageLabel.text = content.filename;
                }
                
                [messageLabel addClickTarget:self action:@selector(zoomIn)];
            }
                break;
                
            default:
                break;
        }
        
        [self setNeedsLayout];
    }
}

- (void)zoomIn {
    NSLog(@"zoomIn: %@", _msg.content);
    DIMMessageContent *content = _msg.content;
    switch (content.type) {
        case DIMMessageType_Image: {
            ZoomInViewController *zoomIn = [UIStoryboard instantiateViewControllerWithIdentifier:@"zoomInController" storyboardName:@"Conversations"];
            zoomIn.msg = _msg;
            
            UIWindow *window = [UIApplication sharedApplication].delegate.window;
            UIViewController *root = window.rootViewController;
            UIViewController *top = root.presentedViewController;
            [top presentViewController:zoomIn animated:NO completion:nil];
        }
            break;
            
        default:
            break;
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
    
    // error info button
    NSError *error = [_msg objectForKey:@"error"];
    if (error) {
        CGRect frame = _infoButton.frame;
        CGFloat x, y;
        x = msgImageFrame.origin.x - frame.size.width;
        y = msgImageFrame.origin.y + (msgImageFrame.size.height - frame.size.height) * 0.5;
        frame.origin = CGPointMake(x, y);
        _infoButton.frame = frame;
        _infoButton.hidden = NO;
    } else {
        _infoButton.hidden = YES;
    }
}

- (void)setMsg:(DKDInstantMessage *)msg {
    [super setMsg:msg];
    
    // error info button
    NSError *error = [_msg objectForKey:@"error"];
    if (error) {
        // message
        MessageButton *btn = (MessageButton *)_infoButton;
        btn.title = NSLocalizedString(@"Failed to send this message", nil);
        btn.message = error.localizedDescription;
    }
}

@end

@implementation ReceivedMsgCell

+ (CGSize)sizeWithMessage:(DKDInstantMessage *)iMsg bounds:(CGRect)rect {
    CGSize size = [super sizeWithMessage:iMsg bounds:rect];
    size.height += 24;
    return size;
}

- (void)setMsg:(DKDInstantMessage *)msg {
    [super setMsg:msg];
    
    DIMEnvelope *env = msg.envelope;
    const DIMID *sender = [DIMID IDWithID:env.sender];
    
    // name
    _nameLabel.text = readable_name(sender);
}

@end

@implementation CommandMsgCell

+ (CGSize)sizeWithMessage:(DKDInstantMessage *)iMsg bounds:(CGRect)rect {
    NSString *text = iMsg.content.text;
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
    
    NSString *text = _msg.content.text;
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

- (void)setMsg:(DKDInstantMessage *)msg {
    if (![_msg isEqual:msg]) {
        _msg = msg;
        
        CGFloat cellWidth = self.bounds.size.width;
        CGFloat msgWidth = cellWidth * 0.618;
        
        // time
        NSString *time = [msg objectForKey:@"timeTag"];
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
        } else {
            timeLabel.bounds = CGRectMake(0, 0, 0, 0);
            timeLabel.text = @"";
        }
        
        // message
        UILabel *messageLabel = [self messageLabel];
        messageLabel.text = msg.content.text;
        
        [self setNeedsLayout];
    }
}

@end
