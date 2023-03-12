//
//  ChatManageTableViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DIMConversation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Table view controller for Conversation Details
 */
@interface ChatManageTableViewController : UIViewController

@property (strong, nonatomic) DIMConversation *conversation;

@end

NS_ASSUME_NONNULL_END
