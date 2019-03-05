//
//  ParticipantManageCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"

#import "User.h"

#import "ParticipantManageCell.h"

@implementation ParticipantManageCell

- (void)setParticipant:(DIMID *)participant {
    if (![_participant isEqual:participant]) {
        _participant = participant;
        
        DIMProfile *profile = MKMProfileForID(participant);
        
        // avatar
        CGRect avatarFrame = _avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
        [_avatarImageView setImage:image];
        
        // name
        NSString *name = readable_name(participant);
        name = [name stringByAppendingFormat:@" [%@]", search_number(participant.number)];
        _nameLabel.text = name;
        
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
