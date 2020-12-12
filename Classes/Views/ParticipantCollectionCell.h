//
//  ParticipantCollectionCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Collection view cell for Participants in Conversation Details
 */
@interface ParticipantCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (strong, nonatomic) DIMID participant;

@end

NS_ASSUME_NONNULL_END
