//
//  ParticipantManageCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Table view cell for Contact List waiting to be added to the Group
 */
@interface ParticipantManageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (strong, nonatomic) DIMID *participant;

@end

NS_ASSUME_NONNULL_END
