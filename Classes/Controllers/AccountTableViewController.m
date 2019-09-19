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

#import "Client.h"

#import "AccountTableViewController.h"

@interface AccountTableViewController ()

@end

@implementation AccountTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = client.currentUser;
    if (user) {
        // avatar
        CGRect avatarFrame = _avatarImageView.frame;
        UIImage *image = [user.profile avatarImageWithSize:avatarFrame.size];
        if (!image) {
            image = [UIImage imageNamed:@"AppIcon"];
        }
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

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.prefersLargeTitles = YES;
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
    
    // avatar
    CGRect avatarFrame = _avatarImageView.frame;
    UIImage *image = [user.profile avatarImageWithSize:avatarFrame.size];
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    [_avatarImageView setImage:image];
    //[_avatarImageView roundedCorner];
    
    // name
    _nameLabel.text = user_title(user.ID);
    
    // desc
    _descLabel.text = (NSString *)user.ID;
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    
    if (section == 1) {
        Client *client = [Client sharedInstance];
        return client.users.count;
    }
    
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    NSString *identifier = nil;
    
    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = nil;
    
    if (section == 1) {
        // Accounts
        user = [client.users objectAtIndex:row];
        
        identifier = @"AccountCell";
        cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AccountCell"];
        }
        if ([user isEqual:client.currentUser]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.textLabel.text = user_title(user.ID);
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    //NSInteger row = indexPath.row;
    if (section == 1) {
        return [super tableView:tableView indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    }
    
    return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    //NSInteger row = indexPath.row;
    if (section == 1) {
        return 44;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = nil;
    
    if (section == 1) {
        // All account(s)
        user = [client.users objectAtIndex:row];
        if ([user isEqual:client.currentUser]) {
            return NO;
        }
        return YES;
    }
    
    return NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = indexPath.row;
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = [client.users objectAtIndex:row];
    
    NSString *unrecoverable = NSLocalizedString(@"This operation is unrecoverable!", nil);
    NSString *text = [NSString stringWithFormat:@"%@\n(%@)\n%@\n\n%@",
                      user.name, search_number(user.number), user.ID, unrecoverable];
    
    NSString *title = NSLocalizedString(@"ARE YOU SURE?", nil);
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        [tableView beginUpdates];
        
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // Delete the row from the data source
            [client removeUser:user];
            
            Facebook *facebook = [Facebook sharedInstance];
            [facebook removeUser:user.ID];
            
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else if (editingStyle == UITableViewCellEditingStyleInsert) {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
        [tableView endUpdates];
    };
    
    [self showMessage:text withTitle:title cancelHandler:NULL cancelButton:@"Cancel" defaultHandler:handler defaultButton:@"Delete"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    NSLog(@"section: %ld, row: %ld", (long)section, (long)row);
    
    Client *client = [Client sharedInstance];
    Facebook *facebook = [Facebook sharedInstance];
    
    if (section == 0) {
        // Account
    } else if (section == 1) {
        // Users
        DIMLocalUser *user = [client.users objectAtIndex:row];
        if (![user isEqual:client.currentUser]) {
            [client login:user];
            [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];
            [self reloadData];
            // update user ID list file
            BOOL saved = [facebook saveUserList:client.users withCurrentUser:client.currentUser];
            NSAssert(saved, @"failed to save users: %@, current user: %@", client.users, client.currentUser);
        }
        
    } else if (section == 2) {
        // Functions
    } else if (section == 3) {
        // Terms, About
    }
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    Client *client = [Client sharedInstance];
    
    if ([segue.identifier isEqualToString:@"terms"]) {
        // show terms
        NSString *urlString = client.termsAPI;
        WebViewController *web = [segue visibleDestinationViewController];
        web.url = [NSURL URLWithString:urlString];
    } else if ([segue.identifier isEqualToString:@"about"]) {
        // show about
        NSString *urlString = client.aboutAPI;
        WebViewController *web = [segue visibleDestinationViewController];
        web.url = [NSURL URLWithString:urlString];
    }
}

@end
