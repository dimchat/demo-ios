//
//  SearchUsersTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/3.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIStoryboardSegue+Extension.h"
#import "UIViewController+Extension.h"
#import "User.h"
#import "Facebook.h"
#import "Client.h"
#import "ContactCell.h"
#import "SearchUsersTableViewController.h"
#import "ChatViewController.h"
#import "ProfileTableViewController.h"

@interface SearchUsersTableViewController ()<UITableViewDelegate, UITableViewDataSource> {
    
    NSMutableArray *_users;
    NSMutableArray *_onlineUsers;
}

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UISearchBar *searchBar;

@end

@implementation SearchUsersTableViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.title = NSLocalizedString(@"Search User", @"title");
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerClass:[ContactCell class] forCellReuseIdentifier:@"ContactCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 44.0)];
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    Client *client = [Client sharedInstance];
    
    // 2. waiting for update
    [NSNotificationCenter addObserver:self
                             selector:@selector(reloadData:)
                                 name:kNotificationName_OnlineUsersUpdated
                               object:client];
    [NSNotificationCenter addObserver:self
                             selector:@selector(reloadData:)
                                 name:kNotificationName_SearchUsersUpdated
                               object:client];
    
    // 3. query from the station
    [client queryOnlineUsers];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    Client *client = [Client sharedInstance];
    
    // 4. stop listening
    [NSNotificationCenter removeObserver:self
                                    name:kNotificationName_SearchUsersUpdated
                                  object:client];
    [NSNotificationCenter removeObserver:self
                                    name:kNotificationName_OnlineUsersUpdated
                                  object:client];

    [super viewWillDisappear:animated];
}

- (void)reloadData:(NSNotification *)notification {
    
    NSArray *users = [notification.userInfo objectForKey:@"users"];
    
    DIMID *ID;
    DIMMeta *meta;
    
    if ([notification.name isEqual:kNotificationName_OnlineUsersUpdated]) {
        // online users
        NSLog(@"online users: %@", users);
        
        if (_onlineUsers) {
            [_onlineUsers removeAllObjects];
        } else {
            _onlineUsers = [[NSMutableArray alloc] initWithCapacity:users.count];
        }
        
        for (NSString *item in users) {
            ID = DIMIDWithString(item);
            meta = DIMMetaForID(ID);
            if (meta) {
                [_onlineUsers addObject:ID];
            } else {
                // NOTICE: if meta for sender not found,
                //         the client will query it automatically
            }
        }
        
        //Sort
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [_onlineUsers sortUsingDescriptors:@[sortDescriptor]];
        
    } else if ([notification.name isEqual:kNotificationName_SearchUsersUpdated]) {
        // search users
        
        if (_users) {
            [_users removeAllObjects];
        } else {
            _users = [[NSMutableArray alloc] initWithCapacity:users.count];
        }
        
        for (NSString *item in users) {
            ID = DIMIDWithString(item);
            if (!MKMNetwork_IsPerson(ID.type) &&
                !MKMNetwork_IsGroup(ID.type)) {
                // ignore
                continue;
            }
            [_users addObject:ID];
        }
        
        //Sort
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [_users sortUsingDescriptors:@[sortDescriptor]];
        
        DIMFacebook *facebook = [DIMFacebook sharedInstance];
        NSDictionary *results = [notification.userInfo objectForKey:@"results"];
        id value;
        for (NSString *key in results) {
            ID = DIMIDWithString(key);
            value = [results objectForKey:key];
            if ([value isKindOfClass:[NSDictionary class]]) {
                meta = MKMMetaFromDictionary(value);
                [facebook saveMeta:meta forID:ID];
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *keywords = searchBar.text;
    NSLog(@"****************** searching %@", keywords);
    
    Client *client = [Client sharedInstance];
    [client searchUsersWithKeywords:keywords];
    
    [searchBar resignFirstResponder];
}

#pragma mark - Table delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return _users.count;
    } else if (section == 1) {
        return _onlineUsers.count;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 1) {
        if (_onlineUsers.count == 1) {
            return NSLocalizedString(@"Online User", nil);
        } else if (_onlineUsers.count > 1) {
            return NSLocalizedString(@"Online Users", nil);
        }
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell" forIndexPath:indexPath];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    DIMID *ID = nil;
    if (section == 0) {
        // search users
        ID = [_users objectAtIndex:row];
    } else if (section == 1) {
        // online users
        ID = [_onlineUsers objectAtIndex:row];
    }
    cell.contact = ID;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ProfileTableViewController *controller = [[ProfileTableViewController alloc] init];
    controller.contact = selectedCell.contact;
    [self.navigationController pushViewController:controller animated:YES];
}

@end
