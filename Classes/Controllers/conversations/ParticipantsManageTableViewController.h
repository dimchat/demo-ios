//
//  ParticipantsManageTableViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface ParticipantsManageTableViewController : UITableViewController

@property (strong, nonatomic) DIMConversation *conversation;

- (IBAction)addParticipants:(id)sender;

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC;

@end

NS_ASSUME_NONNULL_END
