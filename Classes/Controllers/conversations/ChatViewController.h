//
//  ChatViewController.h
//  Sechat
//
//  Created by Albert Moky on 2018/12/24.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DIMClient/DIMClient.h>
#import "MessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MessageCellDelegate>

@property (strong, nonatomic) UITableView *messagesTableView;
@property (strong, nonatomic) DIMConversation *conversation;

@end

NS_ASSUME_NONNULL_END
