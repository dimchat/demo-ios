//
//  ParticipantsCollectionViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface ParticipantsCollectionViewController : UICollectionViewController

@property (strong, nonatomic) DIMConversation *conversation;

@end

NS_ASSUME_NONNULL_END
