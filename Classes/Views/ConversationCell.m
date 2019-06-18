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
    DIMContent *content;
    while (--count >= 0) {
        msg = [_conversation messageAtIndex:count];
        content = msg.content;
        switch (content.type) {
            case DIMContentType_Text: {
                last = [(DIMTextContent *)content text];
            }
                break;
            
            case DIMContentType_File: {
                NSString *filename = [(DIMFileContent *)content filename];
                NSString *format = NSLocalizedString(@"[File:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DIMContentType_Image: {
                NSString *filename = [(DIMImageContent *)content filename];
                NSString *format = NSLocalizedString(@"[Image:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DIMContentType_Audio: {
                NSString *filename = [(DIMAudioContent *)content filename];
                NSString *format = NSLocalizedString(@"[Voice:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DIMContentType_Video: {
                NSString *filename = [(DIMVideoContent *)content filename];
                NSString *format = NSLocalizedString(@"[Movie:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DIMContentType_Page: {
                DIMWebpageContent *page = (DIMWebpageContent *)content;
                NSString *text = page.title;
                if (text.length == 0) {
                    text = page.desc;
                    if (text.length == 0) {
                        text = [page.URL absoluteString];
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
