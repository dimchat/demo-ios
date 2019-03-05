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
        
        DIMProfile *profile = MKMProfileForID(conversation.ID);
        
        // avatar
        CGRect avatarFrame = _avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
        [_avatarImageView setImage:image];
        
        // name
        _nameLabel.text = readable_name(conversation.ID);
        
        // last message
        _lastMsgLabel.text = @"...";
        
        [self setNeedsLayout];
    }
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
