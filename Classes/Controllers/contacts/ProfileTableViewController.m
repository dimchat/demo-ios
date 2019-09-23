//
//  ProfileTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSObject+JsON.h"
#import "NSData+Crypto.h"
#import "NSDate+Timestamp.h"
#import "NSNotificationCenter+Extension.h"
#import "UIViewController+Extension.h"
#import "UIStoryboardSegue+Extension.h"
#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"

#import "Facebook.h"
#import "Client.h"

#import "User.h"

#import "ChatViewController.h"

#import "ProfileTableViewController.h"

@interface ProfileTableViewController ()<UITableViewDelegate, UITableViewDataSource> {
}

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIView *headerView;
@property(nonatomic, strong) UIImageView *avatarView;
@property(nonatomic, strong) UILabel *nicknameLabel;
@property(nonatomic, strong) UILabel *searchNumberLabel;
@property(nonatomic, strong) NSArray *actionArray;

@end

@implementation ProfileTableViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.title = NSLocalizedString(@"Profile", @"title");
    self.view.backgroundColor = [UIColor colorNamed:@"ViewBackgroundColor"];
    
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = 235.0;
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    
    width = 120.0;
    height = 120.0;
    x = (self.view.bounds.size.width - width) / 2;
    y = 15.0;
    self.avatarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"default_avatar"]];
    self.avatarView.frame = CGRectMake(x, y, width, height);
    self.avatarView.layer.cornerRadius = width / 2;
    self.avatarView.layer.masksToBounds = YES;
    [self.headerView addSubview:self.avatarView];
    
    width = self.view.bounds.size.width;
    height = 38.0;
    x = 0.0;
    y = self.avatarView.frame.origin.y + self.avatarView.frame.size.height + 13.0;
    self.nicknameLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.nicknameLabel.textAlignment = NSTextAlignmentCenter;
    self.nicknameLabel.font = [UIFont systemFontOfSize:34.0];
    [self.headerView addSubview:self.nicknameLabel];
    
    y = y + height + 10.0;
    height = 18.0;
    self.searchNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.searchNumberLabel.textAlignment = NSTextAlignmentCenter;
    self.searchNumberLabel.textColor = [UIColor lightGrayColor];
    self.searchNumberLabel.font = [UIFont systemFontOfSize:14.0];
    [self.headerView addSubview:self.searchNumberLabel];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ProfileCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.headerView;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DIMUser *user = DIMUserWithID(self.contact);
    NSString *name = !user ? self.contact.name : user.name;
    self.nicknameLabel.text = name;
    self.searchNumberLabel.text = search_number(self.contact.number);
    
    CGRect frame = self.avatarView.frame;
    UIImage *image = [DIMProfileForID(_contact) avatarImageWithSize:frame.size];
    if (!image) {
        image = [UIImage imageNamed:@"default_avatar"];
    }
    self.avatarView.image = image;
    
    [self loadData];
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

-(void)loadData{
    
    DIMLocalUser *user = [Client sharedInstance].currentUser;
    if ([user existsContact:_contact]) {
        self.actionArray = @[NSLocalizedString(@"Chat", @"title")];
    }else{
        self.actionArray = @[NSLocalizedString(@"Add To Contact", @"title"), NSLocalizedString(@"Chat", @"title")];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.actionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
    cell.textLabel.text = [self.actionArray objectAtIndex:indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

#pragma mark - Navigation

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *message = [self.actionArray objectAtIndex:indexPath.row];
    
    if([message isEqualToString:NSLocalizedString(@"Add To Contact", @"title")]){
        
        Client *client = [Client sharedInstance];
        DIMLocalUser *user = client.currentUser;
        
        DIMUser *selectedUser = DIMUserWithID(self.contact);
        NSString *name = !selectedUser ? self.contact.name : selectedUser.name;
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Do you want to add %@ to your contact list?", @"title"), name];
        
        [self showMessage:message withTitle:NSLocalizedString(@"Add To Contact List", @"title") cancelHandler:nil defaultHandler:^(UIAlertAction * _Nonnull action) {
            
            DIMMeta *meta = DIMMetaForID(user.ID);
            DIMProfile *profile = user.profile;
            DIMCommand *cmd;
            if (profile) {
                cmd = [[DIMProfileCommand alloc] initWithID:user.ID
                                                       meta:meta
                                                    profile:profile];
            } else {
                cmd = [[DIMMetaCommand alloc] initWithID:user.ID
                                                    meta:meta];
            }
            [client sendContent:cmd to:self.contact];
            
            // add to contacts
            [[DIMFacebook sharedInstance] user:user addContact:self.contact];
            NSLog(@"contact %@ added to user %@", self.contact, user);
            [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];
            
            [self loadData];
            [self.tableView reloadData];
            
            DIMConversation *convers = DIMConversationWithID(self.contact);
            ChatViewController *vc = [[ChatViewController alloc] init];
            vc.conversation = convers;
            [self.navigationController pushViewController:vc animated:YES];
        }];
        
    } else if([message isEqualToString:NSLocalizedString(@"Chat", @"title")]){
        
        DIMConversation *convers = DIMConversationWithID(self.contact);
        ChatViewController *vc = [[ChatViewController alloc] init];
        vc.conversation = convers;
        [self.navigationController pushViewController:vc animated:YES];
        
    }
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSLog(@"contact: %@", _contact);
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = client.currentUser;
    
    if ([segue.identifier isEqualToString:@"startChat"]) {
        
        DIMConversation *convers = DIMConversationWithID(_contact);
        
        ChatViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = convers;
        
    } else if ([segue.identifier isEqualToString:@"addContact"]) {
        
        // send meta & profile first as handshake
        DIMMeta *meta = DIMMetaForID(user.ID);
        DIMProfile *profile = user.profile;
        DIMCommand *cmd;
        if (profile) {
            cmd = [[DIMProfileCommand alloc] initWithID:user.ID
                                                   meta:meta
                                                profile:profile];
        } else {
            cmd = [[DIMMetaCommand alloc] initWithID:user.ID
                                                meta:meta];
        }
        [client sendContent:cmd to:_contact];
        
        // add to contacts
        [[DIMFacebook sharedInstance] user:user addContact:_contact];
        NSLog(@"contact %@ added to user %@", _contact, user);
        [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];

        DIMConversation *convers = DIMConversationWithID(_contact);
        
        ChatViewController *vc = [segue visibleDestinationViewController];
        vc.conversation = convers;
        
        // refresh button 'Add Contact' to 'Send Message'
        [self.tableView reloadData];
    }
}

@end
