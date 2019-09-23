//
//  ParticipantCollectionCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"

#import "User.h"

#import "ParticipantCollectionCell.h"

@implementation ParticipantCollectionCell

- (void)setParticipant:(DIMID *)participant {
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
        image = [UIImage imageNamed:@"default_avatar"];
    }
    [_avatarImageView setImage:image];
    _avatarImageView.layer.cornerRadius = frame.size.width / 2;
    _avatarImageView.layer.masksToBounds = YES;
    
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
    [_nameLabel removeFromSuperview];
    [self.avatarImageView addSubview:_nameLabel];
}

@end
