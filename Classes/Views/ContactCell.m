//
//  ContactCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Extension.h"
#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"
#import "Facebook+Profile.h"
#import "User.h"
#import "ContactCell.h"
#import "UIColor+Extension.h"
#import "DIMClientConstants.h"

@implementation ContactCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
        self.avatarImageView.layer.cornerRadius = 22.0;
        self.avatarImageView.layer.masksToBounds = YES;
        [self.contentView addSubview:self.avatarImageView];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.font = [UIFont systemFontOfSize:16.0];
        [self.contentView addSubview:self.nameLabel];
        
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.descLabel.font = [UIFont systemFontOfSize:13.0];
        self.descLabel.textColor = [UIColor colorWithHexString:@"9f9f9f"];
        [self.contentView addSubview:self.descLabel];
        
        self.separatorInset = UIEdgeInsetsMake(0.0, 70.0, 0.0, 0.0);
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(didAvatarUpdated:)
                   name:kNotificationName_AvatarUpdated object:nil];
        [nc addObserver:self selector:@selector(didProfileUpdated:)
                   name:kNotificationName_ProfileUpdated object:nil];
        [nc addObserver:self selector:@selector(didGroupMemberUpdated:)
                   name:kNotificationName_GroupMembersUpdated object:nil];
    }
    
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setContact:(DIMID)contact {
    _contact = contact;
    [self setData];
    [self setNeedsLayout];
}

-(void)setData{
    
    CGRect frame = self.avatarImageView.frame;
    
    UIImage *image;
    if ([_contact isGroup]) {
        image = [DIMProfileForID(_contact) logoImageWithSize:frame.size];
    } else {
        image = [DIMProfileForID(_contact) avatarImageWithSize:frame.size];
    }
    
    [_avatarImageView setImage:image];
    
    if(_contact.type == MKMNetwork_Group){
        
        DIMGroup group = DIMGroupWithID(_contact);
        NSString *name = !group ? _contact.name : group.name;
        self.nameLabel.text = name;
        self.descLabel.text = search_number(_contact.number);
        
    }else{
        DIMUser user = DIMUserWithID(_contact);
        NSString *name = !user ? _contact.name : user.name;
        self.nameLabel.text = name;
        self.descLabel.text = search_number(_contact.number);
    }
}

- (void)didAvatarUpdated:(NSNotification *)o {
    NSDictionary *userInfo = [o userInfo];
    DIMID ID = [userInfo objectForKey:@"ID"];
    if ([ID isEqual:self.contact]) {
        [NSObject performBlockOnMainThread:^{
            [self setData];
            [self setNeedsLayout];
        } waitUntilDone:NO];
    }
}

- (void)didProfileUpdated:(NSNotification *)o {
    NSDictionary *profileDic = [o userInfo];
    DIMID ID = [profileDic objectForKey:@"ID"];
    if ([ID isEqual:self.contact]) {
        [NSObject performBlockOnMainThread:^{
            [self setData];
            [self setNeedsLayout];
        } waitUntilDone:NO];
    }
}

- (void)didGroupMemberUpdated:(NSNotification *)o {
    NSDictionary *profileDic = [o userInfo];
    DIMID ID = [profileDic objectForKey:@"group"];
    if ([ID isEqual:self.contact]) {
        [NSObject performBlockOnMainThread:^{
            [self setData];
            [self setNeedsLayout];
        } waitUntilDone:NO];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat x = 13.0;
    CGFloat y = 10.0;
    CGFloat width = self.avatarImageView.bounds.size.width;
    CGFloat height = self.avatarImageView.bounds.size.height;
    self.avatarImageView.frame = CGRectMake(x, y, width, height);
    
    x = x * 2 + width;
    y = 13.0;
    height = 19.0;
    width = self.contentView.bounds.size.width - 13.0 - x;
    self.nameLabel.frame = CGRectMake(x, y, width, height);
    
    y = y + height + 5.0;
    height = 15.0;
    self.descLabel.frame = CGRectMake(x, y, width, height);
}

@end
