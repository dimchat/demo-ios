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

- (void)setParticipant:(DIMID)participant {
    if (![_participant isEqual:participant]) {
        _participant = participant;
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    MKMVisa *profile = DIMDocumentForID(_participant, MKMDocument_Visa);
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image = [profile avatarImageWithSize:frame.size];
    [_avatarImageView setImage:image];
    
    // name
    NSString *name = profile.name;
    if (name.length == 0) {
        name = _participant.name;
        if (name.length == 0) {
            name = (NSString *)_participant.address;
        }
    }
    _nameLabel.text = name;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    // avatar
    _avatarImageView.layer.cornerRadius = 25.0;
    _avatarImageView.layer.masksToBounds = YES;
}

@end
