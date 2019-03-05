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
        NSString *name = profile.name;
        if (name.length == 0) {
            name = participant.name;
            if (name.length == 0) {
                // BTC Address
                name = participant;
            }
        }
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

@end
