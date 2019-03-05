//
//  ConversationCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"
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
    
    DIMProfile *profile = MKMProfileForID(_conversation.ID);
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image = [profile avatarImageWithSize:frame.size];
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
            case DIMMessageType_Text:
                last = content.text;
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
