//
//  UserCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"

#import "User.h"

#import "UserCell.h"

@implementation UserCell

- (void)setContact:(DIMAccount *)contact {
    if (![_contact isEqual:contact]) {
        _contact = contact;
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    DIMProfile *profile = MKMProfileForID(_contact.ID);
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image = [profile avatarImageWithSize:frame.size];
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    [_avatarImageView setImage:image];
    
    // name
    _nameLabel.text = account_title(_contact);
    
    // desc
    _descLabel.text = (NSString *)_contact.ID;
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