//
//  ContactCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIImageView+Extension.h"

#import "User.h"

#import "ContactCell.h"

@implementation ContactCell

- (void)setContact:(DIMAccount *)contact {
    if (![_contact isEqual:contact]) {
        _contact = contact;
        
        DIMProfile *profile = MKMProfileForID(contact.ID);
        
        // avatar
        CGRect avatarFrame = _avatarImageView.frame;
        UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
        [_avatarImageView setImage:image];
        
        // name
        _nameLabel.text = account_title(contact);
        
        // desc
        _descLabel.text = contact.ID;
        
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
