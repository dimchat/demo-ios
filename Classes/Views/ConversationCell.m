//
//  ConversationCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"

#import "User.h"

#import "ConversationCell.h"

@implementation ConversationCell

- (void)setConversation:(DIMConversation *)conversation {
    if (![_conversation.ID isEqual:conversation.ID]) {
        _conversation = conversation;
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    DIMProfile *profile = DIMProfileForID(_conversation.ID);
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image;
    if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        image = [profile logoImageWithSize:frame.size];
    } else {
        image = [profile avatarImageWithSize:frame.size];
    }
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    [_avatarImageView setImage:image];
    
    // name
    _nameLabel.text = readable_name(_conversation.ID);
    
    // last message
    NSString *last = nil;
    NSInteger count = [_conversation numberOfMessage];
    DIMInstantMessage *msg;
    DIMMessageContent *content;
    while (--count >= 0) {
        msg = [_conversation messageAtIndex:count];
        content = msg.content;
        switch (content.type) {
            case DIMMessageType_Text: {
                last = content.text;
            }
                break;
            
            case DIMMessageType_File: {
                NSString *format = NSLocalizedString(@"[File:%@]", nil);
                last = [NSString stringWithFormat:format, content.filename];
            }
                break;
                
            case DIMMessageType_Image: {
                NSString *format = NSLocalizedString(@"[Image:%@]", nil);
                last = [NSString stringWithFormat:format, content.filename];
            }
                break;
                
            case DIMMessageType_Audio: {
                NSString *format = NSLocalizedString(@"[Voice:%@]", nil);
                last = [NSString stringWithFormat:format, content.filename];
            }
                break;
                
            case DIMMessageType_Video: {
                NSString *format = NSLocalizedString(@"[Movie:%@]", nil);
                last = [NSString stringWithFormat:format, content.filename];
            }
                break;
                
            case DIMMessageType_Page: {
                NSString *text = content.title;
                if (text.length == 0) {
                    text = content.desc;
                    if (text.length == 0) {
                        text = [content.URL absoluteString];
                    }
                }
                NSString *format = NSLocalizedString(@"[Web:%@]", nil);
                last = [NSString stringWithFormat:format, text];
            }
                break;
                
            default:
                break;
        }
        if (last.length > 0) {
            // got it
            break;
        }
    }
    _lastMsgLabel.text = last;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    // avatar
    [_avatarImageView roundedCorner];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
