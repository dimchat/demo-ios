//
//  AccountTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIStoryboardSegue+Extension.h"
#import "UIView+Extension.h"
#import "UIViewController+Extension.h"
#import "DIMProfile+Extension.h"
#import "WebViewController.h"
#import "User.h"
#import "Facebook+Profile.h"
#import "Facebook+Register.h"
#import "AccountEditViewController.h"
#import "Client.h"
#import "ContactCell.h"
#import "AccountTableViewController.h"

@interface AccountTableViewController ()<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;

@end

@implementation AccountTableViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.title = NSLocalizedString(@"Settings", @"title");
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.tableView registerClass:[ContactCell class] forCellReuseIdentifier:@"ContactCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"NormalCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = client.currentUser;
    if (user) {
        // avatar
        CGRect avatarFrame = _avatarImageView.frame;
        UIImage *image = [user.profile avatarImageWithSize:avatarFrame.size];
        [_avatarImageView setImage:image];
        [_avatarImageView roundedCorner];
        
        // name
        _nameLabel.text = user_title(user.ID);
        
        // desc
        _descLabel.text = (NSString *)user.ID;
    } else {
        _nameLabel.text = NSLocalizedString(@"USER NOT FOUND", nil);
        _descLabel.text = NSLocalizedString(@"Please register/login first.", nil);
        
        // show register view controller
        [self performSegueWithIdentifier:@"registerSegue" sender:self];
    }
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(reloadData)
                                 name:kNotificationName_UsersUpdated
                               object:nil];
    [NSNotificationCenter addObserver:self
                             selector:@selector(onAvatarUpdated:)
                                 name:kNotificationName_AvatarUpdated
                               object:nil];
}

- (void)onAvatarUpdated:(NSNotification *)notification {
    
    DIMProfile *profile = [notification.userInfo objectForKey:@"profile"];
    DIMLocalUser *user = [Client sharedInstance].currentUser;
    if (![profile.ID isEqual:user.ID]) {
        // not my profile
        return ;
    }
    
    [self reloadData];
}

- (void)reloadData {
    // TODO: update client.users
    DIMLocalUser *user = [Client sharedInstance].currentUser;
    
    CGRect avatarFrame = _avatarImageView.frame;
    UIImage *image = [user.profile avatarImageWithSize:avatarFrame.size];
    [_avatarImageView setImage:image];
    _nameLabel.text = user_title(user.ID);
    _descLabel.text = (NSString *)user.ID;
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 1) {
        return 2;
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0){
        Client *client = [Client sharedInstance];
        ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        cell.contact = client.currentUser.ID;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NormalCell"];
    
    if(indexPath.section == 1){
        
        if(indexPath.row == 0){
            cell.textLabel.text = NSLocalizedString(@"Terms", @"title");
        }else if(indexPath.row == 1){
            cell.textLabel.text = NSLocalizedString(@"About", @"title");
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0){
        return 64.0;
    }
    
    return 44.0;
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSInteger section = indexPath.section;
//    NSInteger row = indexPath.row;
//
//    Client *client = [Client sharedInstance];
//    DIMLocalUser *user = nil;
//
//    if (section == 1) {
//        // All account(s)
//        user = [client.users objectAtIndex:row];
//        if ([user isEqual:client.currentUser]) {
//            return NO;
//        }
//        return YES;
//    }
//
//    return NO;
//}

// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    NSInteger row = indexPath.row;
//
//    Client *client = [Client sharedInstance];
//    DIMLocalUser *user = [client.users objectAtIndex:row];
//
//    NSString *unrecoverable = NSLocalizedString(@"This operation is unrecoverable!", nil);
//    NSString *text = [NSString stringWithFormat:@"%@\n(%@)\n%@\n\n%@",
//                      user.name, search_number(user.number), user.ID, unrecoverable];
//
//    NSString *title = NSLocalizedString(@"ARE YOU SURE?", nil);
//
//    void (^handler)(UIAlertAction *);
//    handler = ^(UIAlertAction *action) {
//        [tableView beginUpdates];
//
//        if (editingStyle == UITableViewCellEditingStyleDelete) {
//            // Delete the row from the data source
//            [client removeUser:user];
//
//            Facebook *facebook = [Facebook sharedInstance];
//            [facebook removeUser:user.ID];
//
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }
//
//        [tableView endUpdates];
//    };
//
//    [self showMessage:text withTitle:title cancelHandler:NULL cancelButton:@"Cancel" defaultHandler:handler defaultButton:@"Delete"];
//}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    NSInteger section = indexPath.section;
//    NSInteger row = indexPath.row;
//    NSLog(@"section: %ld, row: %ld", (long)section, (long)row);
//
//    Client *client = [Client sharedInstance];
//    Facebook *facebook = [Facebook sharedInstance];
//
//    if (section == 0) {
//        // Account
//    } else if (section == 1) {
//        // Users
//        DIMLocalUser *user = [client.users objectAtIndex:row];
//        if (![user isEqual:client.currentUser]) {
//            [client login:user];
//            [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];
//            [self reloadData];
//            // update user ID list file
//            BOOL saved = [facebook saveUserList:client.users withCurrentUser:client.currentUser];
//            NSAssert(saved, @"failed to save users: %@, current user: %@", client.users, client.currentUser);
//        }
//
//    } else if (section == 2) {
//        // Functions
//    } else if (section == 3) {
//        // Terms, About
//    }
//
//}

#pragma mark - Navigation

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == 0){
        
        AccountEditViewController *controller = [[AccountEditViewController alloc] init];
        controller.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:controller animated:YES];
        
    } else if(indexPath.section == 1){
        
        Client *client = [Client sharedInstance];
        WebViewController *web = [[WebViewController alloc] init];
        web.hidesBottomBarWhenPushed = YES;
        
        if(indexPath.row == 0){
            
            NSString *urlString = client.termsAPI;
            web.url = [NSURL URLWithString:urlString];
            web.title = NSLocalizedString(@"Terms", nil);
            
        } else if(indexPath.row == 1){
            
            NSString *urlString = client.aboutAPI;
            web.url = [NSURL URLWithString:urlString];
            web.title = NSLocalizedString(@"About", nil);
        }
        
        [self.navigationController pushViewController:web animated:YES];
    }
    
}

@end
