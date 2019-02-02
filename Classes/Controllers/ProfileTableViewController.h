//
//  ProfileTableViewController.h
//  DIMClient
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileTableViewController : UITableViewController

@property (strong, nonatomic) DIMAccount *account;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@property (weak, nonatomic) IBOutlet UILabel *seedLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UILabel *fingerprintLabel;

@property (weak, nonatomic) IBOutlet UILabel *localityLabel;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (weak, nonatomic) IBOutlet UILabel *avatarLabel;


@end

NS_ASSUME_NONNULL_END
