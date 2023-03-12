//
//  ParticipantsManageTableViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DIMConversation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Table view controller for Show Contact list and add Group members
 */
@interface ParticipantsManageTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *seedTextField;

@property (strong, nonatomic) DIMConversation *conversation;

- (IBAction)changeGroupName:(UITextField *)sender;

- (IBAction)addParticipants:(id)sender;

- (IBAction)unwindForSegue:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC;

@end

NS_ASSUME_NONNULL_END
