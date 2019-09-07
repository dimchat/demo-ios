//
//  SearchUsersTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/3.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIStoryboardSegue+Extension.h"

#import "User.h"
#import "Facebook.h"

#import "Client.h"

#import "UserCell.h"
#import "ProfileTableViewController.h"

#import "SearchUsersTableViewController.h"

@interface SearchUsersTableViewController () {
    
    NSMutableArray *_users;
    NSMutableArray *_onlineUsers;
}

@end

@implementation SearchUsersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    
    Client *client = [Client sharedInstance];
    
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
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 1) {
        if (_onlineUsers.count == 1) {
            return NSLocalizedString(@"Online User", nil);
        } else if (_onlineUsers.count > 1) {
            return NSLocalizedString(@"Online Users", nil);
        }
    }
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell" forIndexPath:indexPath];
    
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
    
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"profileSegue"]) {
        UserCell *cell = sender;
        
        ProfileTableViewController *vc = [segue visibleDestinationViewController];
        vc.contact = cell.contact;
    }
}

@end
