//
//  ParticipantManageCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"

#import "User.h"

#import "ParticipantManageCell.h"

@implementation ParticipantManageCell

- (void)setParticipant:(const DIMID *)participant {
    if (![_participant isEqual:participant]) {
        _participant = participant;
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    DIMProfile *profile = DIMProfileForID(_participant);
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image = [profile avatarImageWithSize:frame.size];
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    [_avatarImageView setImage:image];
    
    // name
    NSString *name = profile.name;
    if (name.length > 0) {
        name = [NSString stringWithFormat:@"%@ (%@)", name, search_number(_participant.number)];
    } else {
        name = _participant.name;
        if (name.length > 0) {
            name = [NSString stringWithFormat:@"%@ (%@)", name, search_number(_participant.number)];
        } else {
            name = (NSString *)_participant.address;
        }
    }
    _nameLabel.text = name;
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
