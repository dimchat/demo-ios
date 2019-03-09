//
//  ParticipantCollectionCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"

#import "User.h"

#import "ParticipantCollectionCell.h"

@implementation ParticipantCollectionCell

- (void)setParticipant:(const DIMID *)participant {
    if (![_participant isEqual:participant]) {
        _participant = participant;
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    DIMProfile *profile = MKMProfileForID(_participant);
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image = [profile avatarImageWithSize:frame.size];
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    [_avatarImageView setImage:image];
    
    // name
    NSString *name = profile.name;
    if (name.length == 0) {
        name = _participant.name;
        if (name.length == 0) {
            // BTC Address
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

@end
