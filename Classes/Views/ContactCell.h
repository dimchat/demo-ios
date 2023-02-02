//
//  ContactCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Table view cell for Contact List
 */
@interface ContactCell : UITableViewCell

@property (strong, nonatomic) UIImageView *avatarImageView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *descLabel;
@property (strong, nonatomic) id<MKMID> contact;

@end

NS_ASSUME_NONNULL_END
