//
//  ParticipantsCollectionViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DIMConversation.h"

NS_ASSUME_NONNULL_BEGIN

@class ChatManageTableViewController;

/**
 *  Collection view controller for Participants in Conversation Details
 */
@interface ParticipantsCollectionViewController : UICollectionViewController

@property (strong, nonatomic) DIMConversation *conversation;
@property (strong, nonatomic) ChatManageTableViewController *manageViewController;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
